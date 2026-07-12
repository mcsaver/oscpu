# Evidence Index

## 基本信息

- `task_id`: 2026-07-12-rv64-f1a-bpu-static-taken
- `task_slug`: rv64-f1a-bpu-static-taken
- `profile`:
- `asset_count`: 847
- `total_size_bytes`: 18644226

## 证据资产

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-green/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-green/summary.txt

- `kind`: txt
- `size_bytes`: 323
- `line_count`: 10
- `sha256`: cd04d2cb3d2c24ab088b3ffda21c607c464c4ec197a1387aa00b9628169dec11
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=323 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-green - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_ooo...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-red-ticked/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 1019
- `line_count`: 9
- `sha256`: b2d26d3cc2d11f234a605db8fd63f38e1fad30cf0ac1d560e635932a8e1117da
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"ERROR": 2, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=1019 bytes; lines=9; FAIL=2; ERROR=2; PASS=2; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-red/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: 2ebec8cf622d1e0a176c4ce11aefc647e4aa458d2fb91a61f99a285200a85034
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-red/summary.txt

- `kind`: txt
- `size_bytes`: 321
- `line_count`: 10
- `sha256`: b448c539f2cc80a27696a43d79b2adac8fe97f34650b6db569c2c02c79bb7360
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=321 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-red - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_ooo_b...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/checker-selector-summary.txt

- `kind`: txt
- `size_bytes`: 794
- `line_count`: 17
- `sha256`: 6175a2a9eaed8abd5602e243e5047bfa9cb61a1c2d24731440111d8442e0ed00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=794 bytes; lines=17; PASS=2; tail=F1a independent-review blocker and closure root_cause: DUT hybrid choice uses local_strong for the second selector arm. Debug checker incorrectly used gshare_strong for both lanes. reachable_sequence: 1. reset; train PC0 once taken -> original gshare/local...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/contract-checker-red.txt

- `kind`: txt
- `size_bytes`: 515
- `line_count`: 10
- `sha256`: 71cc85ab920c6e551410e77a8b6d4eadcede956945f79c1da3d2f85d32aebe3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: txt evidence; size=515 bytes; lines=10; FAIL=2; PASS=4; tail=command: python3 yosys-sta/scripts/check_bpu_macro_contract.py exit_code: 1 stdout: PASS bpu-spec facts=17 PASS macro-boundary facts=9 stderr: FAIL bpu-rtl missing contract facts: lookup0_scalar, lookup1_scalar classification: intended RED after checker str...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359857
- `line_count`: 4550
- `sha256`: bf6410ed444dcebf6f0ed2f2313c341edb0a5ea5b7e0489144571bea1e296a92
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359857 bytes; lines=4550; GOOD_TRAP=21; tail=.cpp:1588 statistic] top branch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000070 miss=390 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000080 miss=10 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x800000c4 miss=3 [0m [1;34m[cpu-exec...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/audit-summary.txt

- `kind`: txt
- `size_bytes`: 1461
- `line_count`: 26
- `sha256`: 93b52f7af29758f6ddd5389f99468328e39409afa2614c435eadab8dfacac843
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 28, "SKIP": 4}
- `summary`: txt evidence; size=1461 bytes; lines=26; SKIP=4; PASS=28; tail=command=npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --riscv-tests --log-base .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress started_at=2026-07-12T21:01:42+08:00 finished_at=2026-07-12T21:03:47...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/npc-build.log

- `kind`: log
- `size_bytes`: 47225
- `line_count`: 58
- `sha256`: 8869a51a248abfffa69927a426d1520256c29eb8db2ce0231ebc665d87309bfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__"]}
- `summary`: log evidence; size=47225 bytes; lines=58; symbolic=__0__,__1__,__2__,__3__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: 1f3f14cc206c7a48fa3fc39d29cf4a9d13d301e25f15518531d4e57bcddd4d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5326
- `line_count`: 63
- `sha256`: d69c528b38c4dcad01724a806de831145269285126b7215a35eb3b7bac06a6b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5326 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: 47c39ed3ad1a748b13af85456a331ebe8d27c5b55ac70c6c878e9e38f671555f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: 33e9a37b49f8ba7d282af2840690376eaea988b584433958e3642de9410ec778
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: 115435b5bd27e60ef2feb05ddf3774a6df168c2ec1357b7fe991bde10b8c8003
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5193
- `line_count`: 61
- `sha256`: c0b62f48f24e5de1e56c14ed4226f4994b5b5a54de4754927889c9b226d7d180
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5193 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5256
- `line_count`: 62
- `sha256`: 67c6bfc7aa3bf013360304a09f5219299abfe2b5b6861ec46e51a15c92ecf954
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5256 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5194
- `line_count`: 61
- `sha256`: 7ca41b02fd86487143fd948f1c8d8ef7b0d773356ab5b91fe9558167090e5302
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5194 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: 1327b1fea11df6610eabaef6b22b6d99279580b306adfb710afb87bb11a6485d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5193
- `line_count`: 61
- `sha256`: ddbe9eadc29d2c2ee05a2d51e177ee1be7f300824f18902be5f475bfc0f8a247
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5193 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5256
- `line_count`: 62
- `sha256`: 83b0a78e2dc887826f4f9ac4451984b8495bbc7fa771b72e96f7f8066c56c09f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5256 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5194
- `line_count`: 61
- `sha256`: 0fdb087f7268953464fe6cef9914470c3c1545659f22d45a4d7a02c793848510
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5194 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5323
- `line_count`: 63
- `sha256`: df4ef78d2d308994e961bf733d585ec7437ed12abfdd9dcd0fc899f48c271dcc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5323 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5323
- `line_count`: 63
- `sha256`: b2ca99c8eea7f076a6b7cbc7d4034ec426d3f31270bacc6ef483f7a989b5f5bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5323 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5256
- `line_count`: 62
- `sha256`: da045b5fb72507e2e0b637a7eb0dc7edc3b56acfaf0ccc2e8d96df2e69291aee
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5256 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5256
- `line_count`: 62
- `sha256`: af639faa586d6ac6ae7a5775a731048e827514a905b29b48dee76ae5e8d756bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5256 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5324
- `line_count`: 63
- `sha256`: 71a98dc81dce48334d4fe881c26846f76f5b3369ba1a777f407eafbb5679dc67
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5324 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5464
- `line_count`: 65
- `sha256`: 90528fab0318d4c2cdbb96c02b946ba66026e9fe7732b8e29b91c21bb208cdf1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5464 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5633
- `line_count`: 66
- `sha256`: e7e0768a27d786ad90dff4c8c62748c18173b586354db4761bf24e08f84cb22d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5633 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5629
- `line_count`: 67
- `sha256`: 119b7fb5ace722942cf9cdc3467196a7baa0c4740a3610824359fcb8ad0f9eb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5629 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5414
- `line_count`: 64
- `sha256`: c76e34a00f53b9e770ff2d09e23f74bacc121f3b473f3888f27c30e85467a616
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5414 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5469
- `line_count`: 65
- `sha256`: 9f4b2428f1641621e6d19b62dbe75139c21b51b9266381a394276ea09fd4bc37
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5469 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: fe14c0cf518576f190aac0bb79a61661fe87e059a87d492b5aac30832cf2b7bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5481
- `line_count`: 65
- `sha256`: 59e1837563320249b4041e07616c298cd26d282d02e61694b17d45051eaf9cfe
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5481 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5508
- `line_count`: 65
- `sha256`: dde2661d25fcdfdd8b59fefbed17c3eec21176b1b435cbc4d29746d156486159
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5508 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: 98856daee853f668606f53baec5e6a2ac9097da9719deff4687b5e2e4c27421e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5485
- `line_count`: 65
- `sha256`: f764231088b4572619c0b95c525b7da55ee7c1373c226bced34050958fecb734
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5485 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5495
- `line_count`: 65
- `sha256`: 12a55262a7d92d593159e965130b25c336584883f0f701f8f68fac7cc20915cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5495 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5330
- `line_count`: 63
- `sha256`: 0eb240439f954dc7078c5fa9ed10c225b68794e64539018ed4240dc44bc2faa2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5330 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5495
- `line_count`: 65
- `sha256`: bd2f635756fc38b956949dd2059122b94aa8b2faaf490625d4a547ff757314fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5495 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5197
- `line_count`: 61
- `sha256`: 8de8ac6d20989f9d8f3b558d15818107666296b8782d13ace9ac162e0a4bf937
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5197 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5618
- `line_count`: 67
- `sha256`: 67c7b8612dfbb924b785b58fafb959b6dff7a49f087093f1c84143cc29780829
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5618 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5415
- `line_count`: 64
- `sha256`: 2408190991a6b4e541753ee6589a673cfe556085c30aa77359b5883945d970f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5415 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5469
- `line_count`: 65
- `sha256`: d127f61532fd8bb892857f89b5f235798e2029c748644ced4d334f54c57b31b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5469 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5485
- `line_count`: 65
- `sha256`: bd63a8f7f2ceb55da2f18bc8d3b8bd2b4642828c4e65ae479fd63d14594ecb8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5485 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5334
- `line_count`: 63
- `sha256`: d79bde597c19688d461367a706b2801afa54164bd187ec0e8bf6ee66a8643f83
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5334 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5505
- `line_count`: 65
- `sha256`: c01fdcb668bc2a745b53f5a92dacd599c13cacaa30069df8d9d50ce93d6411da
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5505 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5488
- `line_count`: 65
- `sha256`: 8798cf33cafcb61de3f71b47b3a191d11c58b7126103c6b6da860e51f10a1a55
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5488 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5486
- `line_count`: 65
- `sha256`: 719f1ca49bbca916646f5f32c8cfaa125977568d1c35ffcaf014857b9009d805
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5486 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: f5585a3719f4e93518cdf6e4d41563586d915b04502a33ed7cc217e1f80992bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5251
- `line_count`: 62
- `sha256`: ff5632f4fd10ce2fcd66145bae67370fdaf27aa6dbe91255e4d842dda2bb7c03
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5251 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5476
- `line_count`: 65
- `sha256`: 35fdfc88c4f1a9d9f6a7692ee75fcb68272910913b44df723d75bd6d5a8980a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5476 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5259
- `line_count`: 62
- `sha256`: 4dfb6cf73d76647d0fbbb4531af5f8061b55e0fccbc3f04407a2bebe50def945
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5259 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 1bf577e1c2f6d4f61a844f7e2c67b7316913cd280d1ec66ce312cb7f4b4686ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5687
- `line_count`: 68
- `sha256`: 459a26a427ac2a4c6df356365edf512072bf905271a400bc07ad91f392d7cba9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5687 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 015092ff09b7208fc810b865ad64e44a3526825a79a1e1c9386da8fb71498aad
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 7c7272909c440262f77997cafedc43246a6f463ef08d8e04744d1f2de4c6fa21
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: b85f7ce68c1d807756426e63be8564d6ecb2d57a7987f704e049c972b18eac75
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5687
- `line_count`: 68
- `sha256`: 5bebc90612e4180a4d4964370e79cc29a8d1d190d6f40655085782f900038e23
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5687 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5250
- `line_count`: 62
- `sha256`: 2b871abc35ba5f7950f114998712a2bbec9545774fd2901c76fa24fda8270b4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5250 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 417ae24945f67cc7087e7e596b1ddb0e4af7e6d1edfdadfbae55f62ae6ab5be6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: c0257e7c35cf84a8eb1a965b967e30549b6c12335553a291fbdc8f7bf972d693
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 67b45e9b3811a68f2be3164ea123e480fc99bb6e4f1f54c58e0f6a60944d6955
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 4ba414ea92c944bf0b645699d5d08c9d85465f29f2ef47e0ad04fcd374a3afbc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 6ca7b49dac75c115e6113194d937182c2254df43a247483baa8acb81046c2007
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 4da3f6b069bf831389592a20cc932113803215bf59f548e7f9f5522494c1c020
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5501
- `line_count`: 65
- `sha256`: 176cbde4057ee92fe9a1ffd575d3d809e6377f1c9c0b34b7e22fbb1fccfff7ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5501 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5245
- `line_count`: 62
- `sha256`: b235b9a8e6894242f023a47919edcda6a93af0bb988508e82745228846872eec
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5245 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5617
- `line_count`: 67
- `sha256`: a443ad4e59f607aa3bc6c4e3b8ad725413a45d54704808ac0a19f51fb4e16c44
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5617 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 9e29a5bfe609d3e0f1a2adc4f3e8431c213739320d1b83433fb40ceca9dbdcd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: fdb62f11c03b5a9d0400dcbe81cc5fb7c6d0b058b969835b353f07fcf516e0bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: ece859620ab102cac5268548675e0213079b6425ee25fc753cd41a6a7beb510f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5736
- `line_count`: 68
- `sha256`: bba153db1ee116f720066c59a2ee5e7105a823500bf06fd601b325bb028b5a4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5736 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: 37bd5aba9b6d584403f36ddeb7eefe77ce7318627da4a38e261f38d9bd4f7383
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: 8577f03c47301b36e3d4eb2d6a6d3c6ceef9630b19d774b7e14e58673df1c60d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5320
- `line_count`: 63
- `sha256`: b6242b3d699db4e8a73ded5660acaf98d9503b5b5d087bfa083d72d81ab935be
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5320 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: ce40e880b0855644e55c3772b6d2dc2e6cf18f38b5977d6faa4200906c489d92
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 698277a28e78925dc5d2f33603a29bb90c42425978e7b87cd44a9563f861392b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5744
- `line_count`: 68
- `sha256`: 18094154ed8a2238967ae9c5af907de30d3e93e99b5bb83b534216d0b0dccef8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5744 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 2b6e22a7860ffa953594251a9aedbe3700f47f58479a2089d4959bb78a4ece9b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5686
- `line_count`: 68
- `sha256`: 48f51e981141fa2924c656abf9c5179a58f88ee69c73ab38881f75c78dd3a17f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5686 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: cfad08d49fab7856465f3b9f998013331082e1dd4d3149c757821ff141f9e90b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: a62d391cde733e69635a0edc1f32ab8dfb5fac5cb84eebb164ed7ebd7f3c3951
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 5a8f7e9760f7c1a8bcfad6b8b416c8ab8be0a80eff525471329930782f9cfbd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5176
- `line_count`: 61
- `sha256`: 0d2ba14f164724ada2e5025f85e5797e5d837ea777a7a9ede2b3a3053ac437dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5176 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: b525a0e63a686674eeda9d84898d965d6e01c1ad9cb8cc8c336a7197b5dd51c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5687
- `line_count`: 68
- `sha256`: 29ef0456f2b452ec7e37ac594f2ed7e589cfc7c37f731c85ca757b1bff9b5efa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5687 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 09eb78277a2214ca800c8b50f8be28e2dad79780174352caaab55ff8863c056d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 5da877ef05c677ee74f6020fc0e63a07c4648a8618aa63c3bd029fc259917d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 25b42ff57e6a73b76f65ea9448a379546984d1e264db69ebfe2505801599427b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5687
- `line_count`: 68
- `sha256`: b9ac9b96382ab59884157d64b9d000d708141d000b67c6372c84be7f54845ce3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5687 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 460121b9dd1f35c19682cf0801ebb043fb61cbdf8b9f13ddc62b0f12478edf83
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 45c11c053d69969c5325bc0117a75a7990957e1f0a5a953ab99112dc207f6190
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: e1a3347437dc43fd6ca24eed1cf1f33537957b097c25eac7ffb4c4434c0924f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5687
- `line_count`: 68
- `sha256`: f8e902ff7a1212486ba3febc663d7e84a5e2316683fccbcb082b8ff47fb2b4d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5687 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: fb6a5c76f60a2fe7b7978c1f582105c2c5fe307cc4650d906421c629690ff22d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: de42b6e78257836ab154bb5d161376ba6aa7c6d95e16a5a16c3e4cad4fddd189
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 2fee267d91c47cdbc91849b76739ef1b41d74b10e046f9a2dadd589093a355f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 812c025a16312421617f47862dc651a68e1f8a64ac9ddeea95658cd5bd1f6739
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 858b8cd3d781b3141fc4955a71363509c9894faa715e54231f73d5cd74628d99
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: cd0f44dc1ce276714e290c9a456c30214c08a178e27724b7dd9828012d6db776
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5502
- `line_count`: 65
- `sha256`: 5ce1955e2aac2c4d77d189e809cf23d69607aff5049ce32ec5f16a15cd9e1423
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5502 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: c25619e446c843b7132736313ddd531cf53c8a29649bbfd8bb2baac7844e7466
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 01db3b96330428d69f2c2ba1bc2c3af30af7a83c5db908a0e2a1d785a0193b45
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 162622ece61db39e689babbdbe5c3b5d5018fa8a326fe5949a8b66e406131125
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 8b390da964a31ed48d40da3f1f068ef39702f775404af27b1aa184d60bfa43c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5687
- `line_count`: 68
- `sha256`: d17ac418725d33072033868e248fc7acd5270e2dc82525d7d03edf85e166abc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5687 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5324
- `line_count`: 63
- `sha256`: b1a30324cf69f53c81ec6b424af2584338363d1126165980a632a60b8e3626f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5324 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5465
- `line_count`: 65
- `sha256`: d9cc619111ba8e442f094d3cfe92db5eba38888b41b64b8e53c7162dbd8bf3d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5465 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5328
- `line_count`: 63
- `sha256`: 98685b14eae24e9598caeaf16339753ade9083ebb336fd8846ee81bf0e46a93f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5328 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5466
- `line_count`: 65
- `sha256`: 7bef12c97d4af5d9f33cb494e78f399795394507b961f94a3be0fca0b6458f6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5466 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: e3de0b4b024318d432ec7bc8ff787df115bd5899309f7cb7e89dce10ffd7d3ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: ac4d9dbe9b4a58f2cb450a628bd329aca626fd55bb4a1b6548857af60095c029
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: ec87ab7d6bafa2cc4595954853c7136eb87d700223f74e96d808816075d9a02e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 1dc57140df182a8e1fd11cec3ffd1126f60f462d937759ca6d0c967bd4a3f33b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 46978c720ae554b6a60b8856c2ddd8f29cf687de6d84200465a22bfa2c5105f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5460
- `line_count`: 65
- `sha256`: 4d75c2357205f0b44e68ad32548953df78b61975b13beaf26564491d66d9766b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5460 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5326
- `line_count`: 63
- `sha256`: 428f0902105e52b112f0fc2bc8877241d940e22829bc27f6ec42a97e47f1c962
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5326 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5467
- `line_count`: 65
- `sha256`: aff1ce02b2d7f51bac46253459db6da524ea75fe7fff1afba73401eb726a07c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5467 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5466
- `line_count`: 65
- `sha256`: bb611c90f7a83090a66eb39df06e169fb93c0882671a60b80549cec384bc2ab5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5466 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 86bc6ab0b15c3af7891e64a4557719c6a503d3381f60278d85bf4a6c2d30a9dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: b3a73af6012486cbd398bc1efaa1af03ae42ea814293235aef0b1ccce92d63f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 09a283a0512ac7e7abc2a68db439c348e0b320bf24999cf26dcc41076e8c3e54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: a155dc300f0896a6322da9ac2a7320b1a1e06f3eca5e195ca87f70f45ea0e6df
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: f9d9ab2a619c55a9661452cff863aac84ebfc930da6b0fc433fb52808b297c22
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 582b6f20227a952c3863e8b8349fb7053664bf8575b515c2283717a40ba0c799
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 94ac3e85b419a62c0a050590c178b38db7aef7918ecfc2a083fd4be2e20db2c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 7bacb4d85f1c933d2e079fcb42bd6aff47ddbeeab26958e28423ba2784948207
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 64a94e29057c1d599f58f92521a4db3547fb6434385832f49c32134fda361025
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5478
- `line_count`: 65
- `sha256`: 73581313e5f4b45898e36d7091f017681039253fc209311e3873ed25de02cb38
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5478 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: cc584dc09abe6d2513b36cf81c040b2d4d9e36c77f89f75452c78ff65184976f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5479
- `line_count`: 65
- `sha256`: 5705548f9b881e2f0cb985ae001c9ce774b7cad6704a3291b7b2bc9011183c9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5479 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: b2305927875d5c84fbcaa5b4d5097f6eb127722c3a0bf30310069e18bfe17d0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5478
- `line_count`: 65
- `sha256`: fff79d36caf492b5ea5bf4079718f9e7a474311f56a44665044bc72be5543f92
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5478 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: adf17656f830607a689fa8b1ef9be9e114cb09ab6b3ff24b0ae0de6b30fad397
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: b706c51cafc71af7a20f85478be5a9fa99cab0a77baf141fa43c0a7e5ffced4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: ef8dc13d5e304bed3af7f9a116d9648f3247408edb1db691aeadfaa277cf4727
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: e4d7c828c44c4498fb9af791b5a4a27162c11f73f79604e2cb5a70a492018566
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 59202c25c78650304f9a5131bda86b163b78f14563b2ba2c49e1d49fac8e0f1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 062904c27a186d930e03231000b092391445d25e3c584401e1e497a03bd80409
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 8e077321b321a42b92005343ab4fa3fc9edd970c6ef0a6b9cd4fb2b8ae286b1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 87ca3edd5f626a2bf251a0c41cf0473555cfdab13f1bb314c85448c18b9a06d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 59aad73c8517883e051f3e4006cd4056fe81267f0b1037f23a3b648bce58f814
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 1bc689b4b7a3637d30617af5410eebf6f4a192f1c93c5b1a895a9cd2df3aa2fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: e34f8532e23c708a683e4dcd10358d86e551676798552b37c9908525db523d80
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 465ab4bcf58428b3dad78161580bbb451d2575a8e4828260d1d0e7a002a020a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: bf9e06965bd4cd10859cdaacc5626529911f9aa27f9f69a7c2346d85a1c906ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: cd97a948b306e40fe02b00c859e200c0cecb907d2eec1a06a35ab05fa75d70e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5481
- `line_count`: 65
- `sha256`: fb3863a8c191da2646c36a8e88b15c2cef1365251cfccca9d285ac2b7e988736
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5481 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 7626e6ee3b18adb18b734ec6af1c024b808fc0af3b945cd4983b1a53b7e10602
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 1b934b44789b33f706f99f5ea3ea044f1a1e8e4add6bfe5f93bcbc1bf1e692b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 518e9a6f5c4c7dfa29ecd17af148cfd45909220feda6ad1813386ec6fe64e92f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: a2541fa6b34956b3771101bde7b2bcbd6b817916e3838ff6fed28f136c53d20b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: 4ee3c414d5e43c097603c7325cfe5558901d924a6ad1180fd4db9728eb3e9f4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: 62d006c52b92a1440b7ed5372951bca3855f476eacc82fbc614c38af6ee19647
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 4fc149ec81f6f6714371f30e62d1325cf79fdbe12f5e914fe60d876768fdcc8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 41429476319a48884ff1ccd22df6c2a78f079d4b54716c6f1addc8623d19be29
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 16ae1c95773a95fcc9c873073877ada3ee2691d684e107c21601695e44434f19
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 11e3d8b3d1fde2ed5a11222b3f85f193c8d7671399b62e78626b9c871fae7229
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: d63a5bae41b9dfdf4cc3801580da4fec8ac437c534f4d5e442b9c60daecca951
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: b73778c8823b3cd6f137ec633a163b3305872b358d232c9f698b0e44ff546c0c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 20a95913fe3e1532d1db3f56bb8bb2ee01bb5ba767414d40c614dabd0438f0ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: c6d3c4db19c9189b720ebef1f20b3a8bc6ae4a55b8d1d097dfc49c50bf1de0d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/status.txt

- `kind`: txt
- `size_bytes`: 15462
- `line_count`: 310
- `sha256`: d17aa7f78eacdf2f78c6d898c52e028e5a6d1868fdeecafb0e5d420291f23a50
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 618}
- `summary`: txt evidence; size=15462 bytes; lines=310; PASS=618; tail=npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS rv64ui-p-addiw PASS tohost=0x00000000800010...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127/summary.txt

- `kind`: txt
- `size_bytes`: 15309
- `line_count`: 470
- `sha256`: b226dfe135b04efa15fd28fd32646952f47450dcd4eb0fd2943dfc68ea389776
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 618}
- `summary`: txt evidence; size=15309 bytes; lines=470; PASS=618; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/core-regress/20260712-210142-1697127 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uzbs [2...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/bpu-macro-contract.log

- `kind`: log
- `size_bytes`: 779
- `line_count`: 16
- `sha256`: cf6e9805753266fa6f70570a20f00e344a635d5c5e19cbd690c483fe909db1d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=779 bytes; lines=16; PASS=26; tail=Script started on 2026-07-12 20:53:12+08:00 [COMMAND="python3 yosys-sta/scripts/check_bpu_macro_contract.py" <not executed on terminal>] PASS bpu-spec-current-section facts=17 PASS macro-boundary-current-row facts=9 PASS bpu-rtl facts=2 PASS frontend-owner...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/commands.txt

- `kind`: txt
- `size_bytes`: 1431
- `line_count`: 12
- `sha256`: ef4de79cd16d8c669c07a123d3ec39483b21961f1ae4d1efb6086421b5f92e6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: txt evidence; size=1431 bytes; lines=12; markers=<none>; tail=共同前置：source scripts/agent-env.sh 1. sha256sum npc/rv64/vsrc/debug/OooBranchDirectionPredictorChecker.sv npc/rv64/testbench/tests/tb_ooo_branch_direction_predictor.sv npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v npc/rv64/vsrc/frontend/OooFrontend.v 2...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/contract.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 7
- `sha256`: 31bf24150f01a0b914a7fa56ec68ac18029319a178a4021ddea47f027ec365d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=456 bytes; lines=7; PASS=2; tail=Script started on 2026-07-12 20:53:07+08:00 [COMMAND="make -C npc/rv64 check-contract" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=38 基线=38 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ /...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/focused-driver.log

- `kind`: log
- `size_bytes`: 896
- `line_count`: 16
- `sha256`: dd071b7e1f40d945377a2a7d1ccd9b51a49e50c54792f502ab17045d5308c3b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=896 bytes; lines=16; PASS=4; tail=Script started on 2026-07-12 20:52:28+08:00 [COMMAND="make -C npc/rv64/testbench RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/focused TESTS="tb_ooo_branch_direction_predictor tb_ooo_...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/focused/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/focused/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: dd2eebc6d7b0b3d2ddad54323e21227330db14ddc9b6c341932a3870056e1c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/focused/summary.txt

- `kind`: txt
- `size_bytes`: 359
- `line_count`: 11
- `sha256`: ec286307fe4bbdba8642af608deb4fdb3517421eff431a64ca43a60172220b89
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=359 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/focused - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_o...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/four-macro-contract.log

- `kind`: log
- `size_bytes`: 652
- `line_count`: 8
- `sha256`: fd4c4584f0dcee65b004a12dddf8f8a60872e3201a654ef9f068dc4ad6188384
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=652 bytes; lines=8; PASS=10; tail=Script started on 2026-07-12 20:53:19+08:00 [COMMAND="python3 yosys-sta/scripts/check_macro_contracts.py --skip-netlist" <not executed on terminal>] PASS spec contract rows modules=4 path=npc/rv64/design/specs/yosys-macro-boundary-contracts.md PASS rtl modu...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/freshness.log

- `kind`: log
- `size_bytes`: 1977
- `line_count`: 18
- `sha256`: 6fc3471312ce0adf27549ef22083b0e886dbdcd01efdbb11daaeaf0f81065117
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=1977 bytes; lines=18; markers=<none>; tail=Script started on 2026-07-12 20:53:53+08:00 [COMMAND="rg -n "local_strong|mixed selector" npc/rv64/vsrc/debug/OooBranchDirectionPredictorChecker.sv npc/rv64/testbench/tests/tb_ooo_branch_direction_predictor.sv && stat -c "%y %n" npc/rv64/vsrc/debug/OooBranc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/lint.log

- `kind`: log
- `size_bytes`: 9007
- `line_count`: 9
- `sha256`: cf09e552f74d41c617729a15eb8f6c826b2a07ab87976f6e35433f95bebaaf7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=9007 bytes; lines=9; markers=<none>; tail=Script started on 2026-07-12 20:52:52+08:00 [COMMAND="make -C npc/rv64 lint" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/l...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module-driver.log

- `kind`: log
- `size_bytes`: 3464
- `line_count`: 101
- `sha256`: 1bc86aa0cca7d68aff740a827ffb89876ec8c9ef5edc19f0e7fcd95ba17419c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 174}
- `summary`: log evidence; size=3464 bytes; lines=101; PASS=174; tail=Script started on 2026-07-12 20:52:34+08:00 [COMMAND="make -C npc/rv64/testbench RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module run" <not executed on terminal>] make: Entering d...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3131
- `line_count`: 27
- `sha256`: 77e982356fad6ca71a642cb7bdf664411e030b9c37ab75bce87ef26f77c82b2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3131 bytes; lines=27; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14816
- `line_count`: 91
- `sha256`: 6fb736de998e48cf84f0ab90c764e46dd9640e3d2d8812c110a7c122641453a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14816 bytes; lines=91; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14492
- `line_count`: 89
- `sha256`: cb5943ea83cac758fceec4a67961a742be7e3614c15acc1637138b6008037e54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14492 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: 5f399347499bc409c478a2226b1cae704a0b6c44d52563fb71e948980546d966
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17360
- `line_count`: 80
- `sha256`: a4b6435bcb69e5353facc2811fe4e6e9f8f6832cc19be52d1018111a3bb9047c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17360 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8629
- `line_count`: 61
- `sha256`: 41cfec95392b5abd6193913dd468b487a3188c125a5a318c38ff03d28a304ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8629 bytes; lines=61; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: ec244762b75132b0f6ab06676f4454670d34b265dded7558bf82621862ce056d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 6239028902f3e8ec0a26df0b9ef979adbdf27fe7f50d9be13f31bcbfd841d08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: dd2eebc6d7b0b3d2ddad54323e21227330db14ddc9b6c341932a3870056e1c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17370
- `line_count`: 80
- `sha256`: 9b75855e42218972038f41a925f444e2766b62f19031f16fd632024732a55a52
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17370 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13729
- `line_count`: 87
- `sha256`: afd1fefafbf18033dee987085379bb4ca1c9eaf51411dde2e697c6eb3e5c62d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13729 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7248
- `line_count`: 54
- `sha256`: e9e9535f0f5921ab4a8bbe221d658fdf98e171f8f580b3c212d74c303922ada4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7248 bytes; lines=54; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: f594914716059ac375c26e4aa9f5ae4bad66b86e259a25a683a128b62235970d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 694
- `line_count`: 7
- `sha256`: 6b7d5423ef11199618478b4b3977c6b9cae3f9043498163520b419555b9edfce
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=694 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17346
- `line_count`: 80
- `sha256`: 27664acabfda43abfedc287eae986e5c1e00c21f3981fcc3443a53b184a97f00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17346 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155876
- `line_count`: 1115
- `sha256`: 57d8e3829508a912e0fa0f816fa3ccefa51ef4f9c22da2971c7a697c036df9ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155876 bytes; lines=1115; PASS=2; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module/summary.txt

- `kind`: txt
- `size_bytes`: 2912
- `line_count`: 96
- `sha256`: 7e65f2d9fba06bb98499dc15b21c1cfe969a0680b7b67364e56f4d3f891713f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 174}
- `summary`: txt evidence; size=2912 bytes; lines=96; PASS=174; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/module - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_pi...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/python-compile.log

- `kind`: log
- `size_bytes`: 258
- `line_count`: 3
- `sha256`: 92307717db6e83d65574e2bca73654924fb4946df8b69d3db9273076e1a45e8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=258 bytes; lines=3; markers=<none>; tail=Script started on 2026-07-12 20:53:26+08:00 [COMMAND="python3 -m py_compile yosys-sta/scripts/check_bpu_macro_contract.py npc/rv64/syn/macro-lib/gen_macro_libs.py" <not executed on terminal>] Script done on 2026-07-12 20:53:26+08:00 [COMMAND_EXIT_CODE="0"]

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/rtl-style.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 6
- `sha256`: 23ea4fd3474245272e63fe0fa1829530ac7fd96ab7516c394ba870a7f6866165
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=411 bytes; lines=6; PASS=2; tail=Script started on 2026-07-12 20:53:02+08:00 [COMMAND="make -C npc/rv64 check-rtl-style" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/source-identity.log

- `kind`: log
- `size_bytes`: 847
- `line_count`: 7
- `sha256`: 603b82253e95a7ee177363cdc75b1d2e1b25d6cf106bcb4d3bd9f4393a0c25e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: log evidence; size=847 bytes; lines=7; markers=<none>; tail=Script started on 2026-07-12 20:52:20+08:00 [COMMAND="sha256sum npc/rv64/vsrc/debug/OooBranchDirectionPredictorChecker.sv npc/rv64/testbench/tests/tb_ooo_branch_direction_predictor.sv npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v npc/rv64/vsrc/fronte...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/final-validation/summary.txt

- `kind`: txt
- `size_bytes`: 2361
- `line_count`: 45
- `sha256`: af16819969aeb99d9bce70f71149c8bf47eb1f08c9907fbb9e42e1bd1076677c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 12}
- `summary`: txt evidence; size=2361 bytes; lines=45; PASS=12; tail=# F1a 最终功能验证摘要 - 日期：2026-07-12 +0800 - 共同环境：`source scripts/agent-env.sh` - 结论：本轮命令清单中的 10 个验证/身份审计命令全部 `rc=0`，未发现失败。 ## 精确结果 1. focused BPU + packet decode：`rc=0`，`2/2 PASS`。 - `tb_ooo_branch_direction_predictor` - `tb_ooo_fetch_packet_decode` 2. 完整 RV64 m...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/focused-green/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: c5861201a1945bd903e9a043787d132e77f73695919748ed7097bc336617a8ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/focused-green/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: dd2eebc6d7b0b3d2ddad54323e21227330db14ddc9b6c341932a3870056e1c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/focused-green/summary.txt

- `kind`: txt
- `size_bytes`: 348
- `line_count`: 11
- `sha256`: a1ec5f712c6060cb98084d56d56b36c03f338619f8b7248460dc31f3c3f33e6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=348 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/focused-green - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_ooo_branch_d...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3131
- `line_count`: 27
- `sha256`: 77e982356fad6ca71a642cb7bdf664411e030b9c37ab75bce87ef26f77c82b2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3131 bytes; lines=27; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14816
- `line_count`: 91
- `sha256`: 6fb736de998e48cf84f0ab90c764e46dd9640e3d2d8812c110a7c122641453a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14816 bytes; lines=91; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14492
- `line_count`: 89
- `sha256`: cb5943ea83cac758fceec4a67961a742be7e3614c15acc1637138b6008037e54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14492 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: c5861201a1945bd903e9a043787d132e77f73695919748ed7097bc336617a8ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: 5f399347499bc409c478a2226b1cae704a0b6c44d52563fb71e948980546d966
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17360
- `line_count`: 80
- `sha256`: a4b6435bcb69e5353facc2811fe4e6e9f8f6832cc19be52d1018111a3bb9047c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17360 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8629
- `line_count`: 61
- `sha256`: 41cfec95392b5abd6193913dd468b487a3188c125a5a318c38ff03d28a304ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8629 bytes; lines=61; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: ec244762b75132b0f6ab06676f4454670d34b265dded7558bf82621862ce056d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 6239028902f3e8ec0a26df0b9ef979adbdf27fe7f50d9be13f31bcbfd841d08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: dd2eebc6d7b0b3d2ddad54323e21227330db14ddc9b6c341932a3870056e1c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17370
- `line_count`: 80
- `sha256`: 9b75855e42218972038f41a925f444e2766b62f19031f16fd632024732a55a52
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17370 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13729
- `line_count`: 87
- `sha256`: afd1fefafbf18033dee987085379bb4ca1c9eaf51411dde2e697c6eb3e5c62d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13729 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7248
- `line_count`: 54
- `sha256`: e9e9535f0f5921ab4a8bbe221d658fdf98e171f8f580b3c212d74c303922ada4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7248 bytes; lines=54; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: f594914716059ac375c26e4aa9f5ae4bad66b86e259a25a683a128b62235970d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 694
- `line_count`: 7
- `sha256`: 6b7d5423ef11199618478b4b3977c6b9cae3f9043498163520b419555b9edfce
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=694 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17346
- `line_count`: 80
- `sha256`: 27664acabfda43abfedc287eae986e5c1e00c21f3981fcc3443a53b184a97f00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17346 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155876
- `line_count`: 1115
- `sha256`: 57d8e3829508a912e0fa0f816fa3ccefa51ef4f9c22da2971c7a697c036df9ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155876 bytes; lines=1115; PASS=2; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green/summary.txt

- `kind`: txt
- `size_bytes`: 2901
- `line_count`: 96
- `sha256`: 3ec4567a33855062caca6630f87d481488e6bb6a21ca1e414a4e52917e68bfd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 174}
- `summary`: txt evidence; size=2901 bytes; lines=96; PASS=174; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/module-green - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_pipe_stage_re...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/negative-probe/OooFrontend.bad.v

- `kind`: v
- `size_bytes`: 294
- `line_count`: 7
- `sha256`: 44005a74be5c9bce5ff2910c3541d4b05077af17b390424da13645a197f193d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: v evidence; size=294 bytes; lines=7; markers=<none>; tail=// BPU-ST1 negative fixture: lane0 intentionally uses the wrong B-imm bit. module OooFrontendBadFixture; OooBranchDirectionPredictor u_branch_direction_predictor ( .lookup0_static_taken_i(fetch_dec0_bimm_w[`XLEN-2]), .lookup1_static_taken_i(fetch_dec1_bimm_...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/negative-probe/result.txt

- `kind`: txt
- `size_bytes`: 416
- `line_count`: 9
- `sha256`: 834a0dbe02891c89141613c3e7718510b981a5d68a8a2869245ac9da2ffbe06a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: txt evidence; size=416 bytes; lines=9; FAIL=2; PASS=6; tail=command: python3 yosys-sta/scripts/check_bpu_macro_contract.py --frontend evidence/negative-probe/OooFrontend.bad.v exit_code: 1 stdout-before-failure: PASS bpu-spec-current-section facts=17 PASS macro-boundary-current-row facts=9 PASS bpu-rtl facts=2 failu...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/structural-red.txt

- `kind`: txt
- `size_bytes`: 365
- `line_count`: 8
- `sha256`: 64f8125df994e2e32db2d274ecc0e1c7a85fb3cd55addb190d6741ad99c5f948
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"FAIL": 2}
- `summary`: txt evidence; size=365 bytes; lines=8; FAIL=2; tail=command: rg scalar-static-taken ABI and reject lookup*_imm_i in OooBranchDirectionPredictor.v exit_code: 1 result: FAIL BPU-ST1 predictor still exposes 64-bit lookup imm matches: 9: input [`XLEN-1:0] lookup0_imm_i 16: input [`XLEN-1:0] lookup1_imm_i 75-76:...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A-check-setup.rpt

- `kind`: rpt
- `size_bytes`: 230
- `line_count`: 4
- `sha256`: 1cdd1050b0d7f35a1bb7d03a63fd684781e0cf6cb1856844153833bb2345ae6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=230 bytes; lines=4; markers=<none>; tail=Warning: There are 303 input ports missing set_input_delay. Warning: There are 1849 output ports missing set_output_delay. Warning: There are 1851 unconstrained endpoints. Warning: There are 109 combinational loops in the design.

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 2b9d6b7407bd606cc7f84f76fbe1ba12fe400436ed2c02623e2404feb5ae1314
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.55e-02 1.09e-04 1.81e-04 9.58e-02 81.7% Combinational 5.97e-03 7.18e-03 4.67e-04 1.36e-02 11.6% Clock 2.80e-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A-top40.rpt

- `kind`: rpt
- `size_bytes`: 324492
- `line_count`: 4085
- `sha256`: ffcfdcfdda561bdc54e1f010c7e5bcef25594931d2da509e00e22a929f4f5e22
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=324492 bytes; lines=4085; markers=<none>; tail=u_core/u_ooo_core/u_frontend/_5122_/Y (OAI21X0P5H7L) 0.072248 16.119661 v u_core/u_ooo_core/u_frontend/_5125_/Y (NAND4BX0P5H7L) 0.092626 16.212288 v u_core/u_ooo_core/u_frontend/_5126_/Y (MUX2X0P5H7L) 0.097229 16.309517 ^ u_core/u_ooo_core/u_frontend/u_fetc...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-check-setup.rpt

- `kind`: rpt
- `size_bytes`: 4224053
- `line_count`: 29157
- `sha256`: 9a554b125559fcb51ba1fc6969210e69271aa1f6c6f9fb87499d6e18db6f3c12
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=4224053 bytes; lines=29157; markers=<none>; tail=xecute_backend/u_core_slice/u_decode_backend/u_int_backend/u_muldiv_unit/resp_valid_o_AOI21X0P5H7L_Y_A1_OAI21X0P5H7L_Y_A1_NOR2X0P5H7L_Y_B_AOI21X0P5H7L_Y_A0_NAND2BX0P5H7L_Y/B u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_m...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-opensta.tcl

- `kind`: tcl
- `size_bytes`: 1238
- `line_count`: 13
- `sha256`: 0d282fd3b83d60f55bee1ebf47a4161cdc05288d8075da61f6bcb8c909ece8a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: tcl evidence; size=1238 bytes; lines=13; markers=<none>; tail=read_liberty /home/lyg/PA/ysyx-workbench/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib read_liberty /tmp/ysyx-bpu-static-a/npc/rv64/syn/macro-lib/Sram4096x199.lib read_liberty /t...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 72d09d5f72965e369e7d89891280cb8256112b52038ef30f962073c5ad296923
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.55e-02 1.13e-04 1.81e-04 9.58e-02 81.5% Combinational 6.00e-03 7.45e-03 4.63e-04 1.39e-02 11.8% Clock 2.80e-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-sign-lane0-path.rpt

- `kind`: rpt
- `size_bytes`: 47806
- `line_count`: 261
- `sha256`: d98611a33a6920e81b5965fc45484db9dad8c283942ae512ebf8ba61a535e72c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=47806 bytes; lines=261; markers=<none>; tail=Startpoint: u_core/u_ooo_fetch_bridge/pc_q_12__reg_p (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding/next_fetch_pc_o[56]_reg_p (rising edge-triggered flip-flop clocked by core_clock) Path...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-sign-lane1-path.rpt

- `kind`: rpt
- `size_bytes`: 50174
- `line_count`: 273
- `sha256`: fdb5749b7a63a1ed759720dd7759a9ef2e057807f023ece18d9c5afbb098f43b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50174 bytes; lines=273; markers=<none>; tail=Startpoint: u_core/u_ooo_fetch_bridge/pc_q_12__reg_p (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding/next_fetch_pc_o[24]_reg_p (rising edge-triggered flip-flop clocked by core_clock) Path...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-sign-main-nets.rpt

- `kind`: rpt
- `size_bytes`: 117027
- `line_count`: 734
- `sha256`: 479756831e1739b506d65394ac9412b6cea809151c64dd070739b7f8bfd9b8d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=117027 bytes; lines=734; markers=<none>; tail=_direction_predictor/lookup0_imm_i[15] input (OooBranchDirectionPredictor) 0.010000 u_core/u_ooo_core/u_frontend/u_branch_direction_predictor/lookup0_imm_i[16] input (OooBranchDirectionPredictor) 0.010000 u_core/u_ooo_core/u_frontend/u_branch_direction_pred...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-sign-net-query.tcl

- `kind`: tcl
- `size_bytes`: 1899
- `line_count`: 14
- `sha256`: e176b4540ba9627cc09fadc47bdd211bb254064a7308cf4292b53af1f0ee3cd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: tcl evidence; size=1899 bytes; lines=14; markers=<none>; tail=read_liberty /home/lyg/PA/ysyx-workbench/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib read_liberty /tmp/ysyx-bpu-static-a/npc/rv64/syn/macro-lib/Sram4096x199.lib read_liberty /t...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/A5bd-top40.rpt

- `kind`: rpt
- `size_bytes`: 1920059
- `line_count`: 9322
- `sha256`: da7acdd9ce5746d6694583887d69a3bbfda3d16cf6f4d63320072386f250e123
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=1920059 bytes; lines=9322; markers=<none>; tail=re/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/issue1_src2_data_w_3__MUX2X0P5H7L_A/Y (MUX2X0P5H7L) 0.066271 12.616437 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/issue1_src2_value_w_3__OAI211X1P4H7L_A1...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-final-check-setup.rpt

- `kind`: rpt
- `size_bytes`: 4224053
- `line_count`: 29157
- `sha256`: 9a554b125559fcb51ba1fc6969210e69271aa1f6c6f9fb87499d6e18db6f3c12
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=4224053 bytes; lines=29157; markers=<none>; tail=xecute_backend/u_core_slice/u_decode_backend/u_int_backend/u_muldiv_unit/resp_valid_o_AOI21X0P5H7L_Y_A1_OAI21X0P5H7L_Y_A1_NOR2X0P5H7L_Y_B_AOI21X0P5H7L_Y_A0_NAND2BX0P5H7L_Y/B u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_m...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-final-opensta.tcl

- `kind`: tcl
- `size_bytes`: 1267
- `line_count`: 13
- `sha256`: a74dcbf669ad9f7545d6e6d3b5bdd7412e09744e6050589875cf8372012a5b5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: tcl evidence; size=1267 bytes; lines=13; markers=<none>; tail=read_liberty /home/lyg/PA/ysyx-workbench/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib read_liberty /home/lyg/PA/ysyx-workbench/npc/rv64/syn/macro-lib/Sram4096x199.lib read_liber...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-final-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 72d09d5f72965e369e7d89891280cb8256112b52038ef30f962073c5ad296923
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.55e-02 1.13e-04 1.81e-04 9.58e-02 81.5% Combinational 6.00e-03 7.45e-03 4.63e-04 1.39e-02 11.8% Clock 2.80e-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-final-top40.rpt

- `kind`: rpt
- `size_bytes`: 1920059
- `line_count`: 9322
- `sha256`: 2df22bcaac430db1ab9bf188c40d2aad05793358c5f1508c2c0181e5430c6e2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=1920059 bytes; lines=9322; markers=<none>; tail=re/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/issue1_src2_data_w_3__MUX2X0P5H7L_A/Y (MUX2X0P5H7L) 0.066271 12.616437 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/issue1_src2_value_w_3__OAI211X1P4H7L_A1...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 72d09d5f72965e369e7d89891280cb8256112b52038ef30f962073c5ad296923
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.55e-02 1.13e-04 1.81e-04 9.58e-02 81.5% Combinational 6.00e-03 7.45e-03 4.63e-04 1.39e-02 11.8% Clock 2.80e-...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-sign-lane0-path.rpt

- `kind`: rpt
- `size_bytes`: 46902
- `line_count`: 261
- `sha256`: 33f278b793cd0e3f694dbba520984f97d11bdfcff4b0fd5b0aa0e3af081a9db5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=46902 bytes; lines=261; markers=<none>; tail=Startpoint: u_core/u_ooo_fetch_bridge/pc_q_12__reg_p (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding/next_fetch_pc_o[61]_reg_p (rising edge-triggered flip-flop clocked by core_clock) Path...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-sign-lane1-path.rpt

- `kind`: rpt
- `size_bytes`: 49656
- `line_count`: 276
- `sha256`: b06b9db1ce4aae91c489d9634c12757d4f4ee2c2b1e0e8ceadc4e20cf5a4411f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49656 bytes; lines=276; markers=<none>; tail=Startpoint: u_core/u_ooo_fetch_bridge/pc_q_12__reg_p (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding/next_fetch_pc_o[62]_reg_p (rising edge-triggered flip-flop clocked by core_clock) Path...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-sign-main-nets.rpt

- `kind`: rpt
- `size_bytes`: 99779
- `line_count`: 648
- `sha256`: d227063ea9827e1fb353d5bd2fe5b4a3bd78f40e97afd1c9be0ef9e4668d1040
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=99779 bytes; lines=648; markers=<none>; tail=H7L_B0_C0_NAND2X0P5H7L_Y_B_XNOR2X0P5H7L_Y_B_XNOR2X0P5H7L_Y/B input (XNOR2X0P5H7L) 0.000662-0.000909 u_core/u_ooo_core/u_frontend/fetch_rsp_packet_next_pc_w_47__OAI211X1P4H7L_A0_Y_OAI21X0P5H7L_B0_A0_XNOR2X0P5H7L_Y_A_XNOR2X0P5H7L_Y/B input (XNOR2X0P5H7L) 0.00...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-sign-net-query.tcl

- `kind`: tcl
- `size_bytes`: 1907
- `line_count`: 14
- `sha256`: 9d03ce2d6819c9d4c5f2708eaac21785b996ff54d3d48fbec5e82e02e7144caf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: tcl evidence; size=1907 bytes; lines=14; markers=<none>; tail=read_liberty /home/lyg/PA/ysyx-workbench/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib read_liberty /home/lyg/PA/ysyx-workbench/npc/rv64/syn/macro-lib/Sram4096x199.lib read_liber...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/B-top40.rpt

- `kind`: rpt
- `size_bytes`: 1920059
- `line_count`: 9322
- `sha256`: 2df22bcaac430db1ab9bf188c40d2aad05793358c5f1508c2c0181e5430c6e2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: rpt evidence; size=1920059 bytes; lines=9322; markers=<none>; tail=re/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/issue1_src2_data_w_3__MUX2X0P5H7L_A/Y (MUX2X0P5H7L) 0.066271 12.616437 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/issue1_src2_value_w_3__OAI211X1P4H7L_A1...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/analyze-top40.awk

- `kind`: awk
- `size_bytes`: 797
- `line_count`: 35
- `sha256`: dc7afe7bc3b8f3f04c14728c45ebe636af142737ccdad36fb60d93fc98ed1a30
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: awk evidence; size=797 bytes; lines=35; markers=<none>; tail=function finish_path() { if (!seen) return total++ if (bridge_start) bridge_starts++ if (fifo) fifo_endpoints++ if (outstanding) outstanding_endpoints++ if (decode) decode_paths++ if (bpu) bpu_paths++ } /^Startpoint:/ { finish_path() seen = 1 bridge_start =...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/input-identity.txt

- `kind`: txt
- `size_bytes`: 2428
- `line_count`: 32
- `sha256`: 4c94a50af894823e2dbe87a76ff6656468ed5816f66ef64adef72b9551367d3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: txt evidence; size=2428 bytes; lines=32; markers=<none>; tail=invalid_old_A_head: c6b86f9a78ce7f84522421c293079fdd1b206f7e fresh_A_head: 5bd7a15464f853a60e4f0c18d5ec3f7dec664af9 production_equivalent_head_before_F1a: 5bd7a15464f853a60e4f0c18d5ec3f7dec664af9 config_sha256: cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/timing/timing-comparison-summary.txt

- `kind`: txt
- `size_bytes`: 2921
- `line_count`: 43
- `sha256`: 9eac180ccbcc744e4d1b1c9c89a9d571072a5dca1e9e84bef3364783094cd39e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {}
- `summary`: txt evidence; size=2921 bytes; lines=43; markers=<none>; tail=F1a fresh 5ns timing A/B 判定 KEEP: scalar static-fallback ABI 删除行为上从未消费的 64-bit immediate 边界， 让 placeholder pin 负载与真实 owner 一致，并显著改善两路 B-imm sign target cone。 NOT CLOSED: full-chip WNS 仍为 -12.895095ns，没有达到 200MHz；top40 全是同一组后端路径。 NON-SIGNOFF: 四颗 macro 面积 unk...

### .github/task-runs/2026-07-12-rv64-f1a-bpu-static-taken/evidence/validation-summary.txt

- `kind`: txt
- `size_bytes`: 784
- `line_count`: 14
- `sha256`: 09f61e8d8664fb4b6358127e728113fd6fd4ab14bc94ffccfcf5e7881ea51f54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T13:14:06+00:00
- `markers`: {"PASS": 18}
- `summary`: txt evidence; size=784 bytes; lines=14; PASS=18; tail=F1a functional validation summary - BPU macro contract checker: PASS (dedicated §8/current macro row + RTL/frontend/debug/generator/lib + no old ABI) - negative owner fixture: expected rc=1, missing lookup0_owner for bimm[XLEN-2] - focused TB: 2/2 PASS (bra...
