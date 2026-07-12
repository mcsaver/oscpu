# Evidence Index

## 基本信息

- `task_id`: 2026-07-12-rv64-ifu-axi-g1-flush-drain
- `task_slug`: rv64-ifu-axi-g1-flush-drain
- `profile`: npc-dev
- `asset_count`: 816
- `total_size_bytes`: 5928488

## 证据资产

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/assert-negative-summary.txt

- `kind`: txt
- `size_bytes`: 1899
- `line_count`: 47
- `sha256`: d0b989c2a00d1d4668be4a8b3dca73c592e6346e267df8c8e3c595f9ef770492
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=1899 bytes; lines=47; markers=<none>; tail=IFU-AXI-G1 immediate-assert non-vacuity probes Command: source scripts/agent-env.sh iverilog -g2012 -Wall \ -I npc/rv64/vsrc -I npc/rv64/vsrc/include -I npc/rv64/testbench/common \ -DOOO_ASSERT -s tb_ooo_fetch_axi_bridge_assert_negative \ -o /tmp/tb_ooo_fet...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359857
- `line_count`: 4550
- `sha256`: 5a00297d5e41f3d3eabf65ddd6f3844d7e8b366d54bcc975d33b0efbee288eae
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359857 bytes; lines=4550; GOOD_TRAP=21; tail=c.cpp:1588 statistic] top branch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000070 miss=390 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000080 miss=10 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x800000c4 miss=3 [0m [1;34m[cpu-exe...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/npc-build.log

- `kind`: log
- `size_bytes`: 48082
- `line_count`: 59
- `sha256`: 6c42625355b57cb5037722f4ba7134858d1f043295262c6f5f52aa23c12e9746
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__"]}
- `summary`: log evidence; size=48082 bytes; lines=59; symbolic=__0__,__1__,__2__,__3__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5257
- `line_count`: 62
- `sha256`: b00b6e2814e95fdd01cf0f37860965b01762337a52b4b95505bc8811c0458079
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5257 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5328
- `line_count`: 63
- `sha256`: 09aafc3c410a4d5b2efdc5fb15bca61f715b6347469f28c4e72d82b33c097e4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5328 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5257
- `line_count`: 62
- `sha256`: cba4e98f67f56439641ec8e3b9b269b46cb12c7f31f670daf98d822a83b9a474
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5257 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5257
- `line_count`: 62
- `sha256`: 244130ac475efd57838b040c3f36ae5c11026ec637e23c999c49d78caea4203e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5257 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5257
- `line_count`: 62
- `sha256`: 1d53f9f7fcdaae3812c3901c97944be6b695c6f020bf5da2ee117fb9479dc0be
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5257 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5195
- `line_count`: 61
- `sha256`: 441dbfd2be4e57c214c6e09efb0286c76de9284dcfacd4fcf3117f012776a11d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5195 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5258
- `line_count`: 62
- `sha256`: 5cf96549717a0c2775c2e87f741a8398d1ff4c4c3115d9c8de859cef30caefcb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5258 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5196
- `line_count`: 61
- `sha256`: c1ee9d5a668416a0bb888c02e25256f486645fe02916f18817ee2f292dc04afc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5196 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5257
- `line_count`: 62
- `sha256`: 4aed074453f142961b0e3c0eed951276d524053bcf1d51ebaaebbbc6a5735a77
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5257 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5195
- `line_count`: 61
- `sha256`: d1f9cadace4fe63bd13562f42ce6acded4887f0d352967b598023e2332198ac7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5195 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5258
- `line_count`: 62
- `sha256`: e15cc28b7645ef7f70e08a563624cdc7a786219d215089203e8ec8aaa11593fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5258 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5196
- `line_count`: 61
- `sha256`: 798e64bbfc729666319f36c82539151f241cb2bcd8c53ef8667aaac77de043d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5196 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5325
- `line_count`: 63
- `sha256`: 984d0e70e1e49c023f90a6d3d4a486812aefb4044e7aa113d5aedf7033e7b57f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5325 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5325
- `line_count`: 63
- `sha256`: c3452e97f9a1f9d84ef1fed74dbed19d431a96f2b239f3e858cf8ab5321d829f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5325 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5258
- `line_count`: 62
- `sha256`: 436f04a215bf32d9b0aaae6fe05ab21e9258fede0d207b26b1c582ff833dbfa1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5258 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5258
- `line_count`: 62
- `sha256`: b613b9f061603f6c79924c7ac6b962959c21396e22d53a7eabbcb4c26caae95f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5258 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5326
- `line_count`: 63
- `sha256`: 45a34832d175bd925a602d9fc67b22f773ec1d1b0382a9fba68036245daefac2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5326 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5466
- `line_count`: 65
- `sha256`: 30047f01c3b4789eb3eab220226629269aa47e1300b3eb384a018ef45773f82a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5466 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5635
- `line_count`: 66
- `sha256`: 4c27256f82293b308831c1bb419e091adca59a2930601569955d903388fbfc07
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5635 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5631
- `line_count`: 67
- `sha256`: 040fc375e9b8e270c07bf6cccd42a4b74761a8b0bba53f870002b8cfebfde92c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5631 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5416
- `line_count`: 64
- `sha256`: 77dd40dea2e482972bfbc04a2d162d1d541e0d77eab8f81c794f978376809f33
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5416 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5471
- `line_count`: 65
- `sha256`: f13372b4731d9b251b684bea4e13e978b96b23caa3cc5203d47f19128512b1e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5471 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5493
- `line_count`: 65
- `sha256`: 126717829c691a657b2a93f44db545b79fb4d63f4863fe6b9e6d6eeb59a76367
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5493 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: 1ca19ca817155cbc6f870b4a5cc2d0fb893b14f32f06a30bba6b7855edb9788a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5510
- `line_count`: 65
- `sha256`: 439bcdc4511f706deaabe510a3cb6c2559dd5cff3683b402631cdf5d8cf054c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5510 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5492
- `line_count`: 65
- `sha256`: d06bb6a6beb1ec16a2add331fb5cb6167dd5014ecc3bbd23aa651ed40f29912e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5492 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: a8d46dfd17928513f2904c4c517af07eb9f59c21b383950c883733027640d348
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5497
- `line_count`: 65
- `sha256`: 1039bf4d4a10b75623f447a6b61a670c9ed508ff88e3427a1d3878eaa01093cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5497 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5332
- `line_count`: 63
- `sha256`: 2ff39f5f4efedc13ae777b7db82dbff56e2e33e1d9e380a029542af027ba71ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5332 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5497
- `line_count`: 65
- `sha256`: d31bb929feaead31daa041562766efb3c34151bfc5a6db81467e22fcc7ad6891
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5497 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5199
- `line_count`: 61
- `sha256`: 7f05eb47b28c4ad6cb28d8e58a8f9414ec017883573db33b03d149d9441b6e10
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5199 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5620
- `line_count`: 67
- `sha256`: d60a140c0c55980a3a207bffcc53a3b77cc0f3fdb2ca0c4e82a895454bcb3fa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5620 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5417
- `line_count`: 64
- `sha256`: 18152653bb9bc47e632ec621f1ab1d4d6b237c6cbcf6505461f15488c3fb524d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5417 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5471
- `line_count`: 65
- `sha256`: 371f5bda5fda403b5fbaa1c5dc4ebbed38a21e5d6e0b5b004675411372e6a1d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5471 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: 006f084413b46279afc98dc847c141847e40d7849ab8dfee0fe5a877c806ae2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5336
- `line_count`: 63
- `sha256`: 4659ca594a09aac6d55e1740d7241459bd9ce4296b6ac850cc7ed9ca3a46e97b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5336 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5507
- `line_count`: 65
- `sha256`: cec7949df159788bf4dc343467c13df1fd24e0662676030a0f4d8c418f50b972
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5507 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: 3876c46656a4064bba6663d419e664f597e1bf7991cb29b3e14f1a95db85a041
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5488
- `line_count`: 65
- `sha256`: 32cdb20e7c24b567a23ae8c470901c4b03096c3a6356b9437a95171e94781850
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5488 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 65c1a260f814bd4ef42b2e8362995b386c0f3158fb1a8a788f54f6c580329f93
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5253
- `line_count`: 62
- `sha256`: a6e12f4affdb03fe2779c06d9b0de01c62ce159f07fe450ddcef0d00c7531950
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5253 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5478
- `line_count`: 65
- `sha256`: 12392e9c830d462647e2b2f2b029972c5a703cdbb3185fe395e06e0da322026f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5478 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5261
- `line_count`: 62
- `sha256`: cbc82d5978ab65c3036a81be8c1ae2e43262acfa956846e1fe34913ee50aa63c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5261 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 078f210e71a736c62d0a8cd989e560419db78833ede77ccf465d3fec976ce8d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 57c99614f86a5f1c48593ac78dbb26683c636502c119a5739d2caa848ed21a56
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 93c7c6dc471839659c06979f26ee20d861cf52a415de87b0f20d382dc815befa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 02420ab25497bd96bbcb656401853bb1ef8e64092da162fd23d200faa0f69f97
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: df98f791b1c9347783b059b427b67b59d88a99b468f6b9630c57d5b1adc6d615
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 9791c788712e674d7a7a081c2f0eb3d889fffbf49bf7d489c32956105e4f9be5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5252
- `line_count`: 62
- `sha256`: 1e065bf185320a2688f9bc2eb5a0bde6e1238020dcd4f29ba4301f0e1df30466
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5252 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: b3e45dd329782fc4fd6657a5a850f496434eea1eb122b7afe5fd55df1f7d1a79
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 93bb5df51d286a5171f0e9f27afe8170c853f750b745721d4566e0c3d07da5ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: c896051baf733066f1f8fb126f7fef08cf12d655590dc180c82b0dfb8da889b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 87ff75310000f66d2ff819124f1365554cc09d806cb21c8f1b7876358d04eb2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 49ce8e41451ee817a895c8bb6f3a1e6575e23e9910174741c8675c3950230bc2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 29e9f3e31b60b346e077b77a7d58120f35c612fd178a083bfed2666ae329fc8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5503
- `line_count`: 65
- `sha256`: 61719e00a61a0bb2228849ff905ee7bef721d110cdf12a3c66af9bcdffbe0a34
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5503 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5247
- `line_count`: 62
- `sha256`: 63b62393e48a27cbfecfe38be8f263dacdc98777ad25f8c3d992fc1dbeb5d0f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5247 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5619
- `line_count`: 67
- `sha256`: 5123efdfdf74996e9670338f49dab3224a1edcf248c0f5c08202152946a6ecad
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5619 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 5bc0988d0a1a5413a5013acc8d957f4abd72a972c02b8b761089b99364a1dee0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 4af9294ffe3c0d7376e632e464e1a48258b75b9e52147cbb66ed39c7c90b526e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 2a9685d4b1fc3a3ce6a794a6d4e9e6e692bb71c4fc2fcf7df5f0891951843153
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5738
- `line_count`: 68
- `sha256`: 6481aa928b5a8b65cf6ea14dad14678fcf8203054a2360ef70f1b16945dde106
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5738 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 57541f191da796854f8ad08689ac4d9cb499233912e74f0cc2b0d7196d9d3207
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 1f90e6e1e640e39e788587c4c6072a9baa61dce7e1744c505d08cf6c8bc77dc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5322
- `line_count`: 63
- `sha256`: 73211a7d4dd812c31e32b67a8a11e64cb188e5338e6eff983fe4776dc2b37c3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5322 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: d71f6500af353e2f619b34aa960f6aa2d3dd5fe3307c1f816b99bb28bd62fee1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 6ed4d8a4d70ae67dc3e056688c0d4a7df31fe5bb946d724597827735895078a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5747
- `line_count`: 68
- `sha256`: b635bed4292cef37f7ced8fdfea1e120b351a63517257411a680e5de106a897d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5747 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 008c55fba68b3aa25ce17c33fc57678aa7c6bb90937463c24f856dcb657b941e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 8a9544d9bb2334af2f98a3550d118f54d24773cb6743fc998a4c391a7aa05282
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: 1dad4860f795d39ec4f48dbc6736cce4499501463ddfab53039496e3cd035422
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: 67053acb381d929a3c8589a5d207f6a186e5f24371bec231a4a9282ac9b8b8c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: af75ed6b73944011e1118315dd0acd3e5b1a18662009b041571bcfc2d293b002
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5178
- `line_count`: 61
- `sha256`: 7f272a181337b004ff8009f355776bed6950dcf92ece53d17d47ba94bc96c6ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5178 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 2f1bbf2e637653c10da8cbf31b32455a2abc5406b93a307bf8dda01d2a1c9c54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 418da7e87378dcab9cd2d78931872c18f243c07c77d6bd2aed0fb642f5c83e71
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 7d39f663f53e7226214bec18f62cd4e44439341988498172fbf5f781a7587f97
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 8082b04c58cf2fb99603757138e8e66a66ec3263e3274837a294c59ef16fca76
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 4a3daca921bcfd9464504b29db0a951deb0563ac760012f073cea1ea69a1b1d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 30f6c2edacb33cb7bfe33d5aaa33294ccd5341a1aa5bb1afebcbbbc5f701053a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 36d78d62ca89a1af61ba04618fbea22409e444e8b2caf0ea445ef81e7523fe7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 389611fa06d2b71a8652cfa3579e427dd764f347d28dae2ec0208319c0a36710
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 24242b9eb0295e857a862bf4eb90c2dcb59031105ca6292efe57bb24d56ec7ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 5642f98d4de29442ac9457c823dd6cbf5097ca9f8972d3044437fc99fdc6b62a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: d710191de612d9f206c3cff55d9386b492df84c5177d4ee1fa78b0d17030ceb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: f6e7fb91146e1478b870b05bc7774bc127854cdb0dac976b5662aa3b84f21def
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: f4d43beabf6c6f30b3114b064104e1c94f1bfaf98b94823af157c00282f43520
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 78950531311bd513226658878b34fd9cf3d2a62742a5ed96aecdee9d3b0739ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 6d9ebad280d933716143c3012b025ac33026a6f0f9ae2ac5771d9274c8f9c516
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: e66603f10d80f820ceaa085b21719b489c7c157fe0068295069b304fa95a372a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5504
- `line_count`: 65
- `sha256`: 8d5d870fe110b17bbf59ad8d2fa5bd3810dfd473f9cafd0472295abe581d0643
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5504 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 4b4c432463dfc61b2fbd5bb99d78cd7f7d68d72c751b9e9140ea96241c48c093
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 43f9743e751b6d191200ccd1d4cad5a9f7005439ec84f5e7cf0fc3b982f2e924
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: e4d5d11facaf05c5fdedb48bc6d4721ae773a5f8050a2a43a50e14377d97a623
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 08f40dd3c86b712740384f436037db93df184e6d1978d78f4fa8a31852646e38
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: a05fb93277b9f3928ac3f9bf7b2eee636735d916e8ed2e56ac24257158241477
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5326
- `line_count`: 63
- `sha256`: 3a8a97c8cb291ccd8761b0e5dc25ae6918f16287871b326e38389e136f7e2c50
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5326 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5467
- `line_count`: 65
- `sha256`: 531a1fdd3742ecda887114ffd783a946a815b593dfa18973ed508ae60fa0978d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5467 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5330
- `line_count`: 63
- `sha256`: 96af56931aa1069c317bbed9ec98ceca41f24bd7df86ae2d5e32b28a7a31081e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5330 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5468
- `line_count`: 65
- `sha256`: f04fb873c14efc9c9a80349cc2250f55cff952dd44d18ad9a196f26ad3d30d76
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5468 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 5bdde887de80820286b5eb5d0b7bbcae712e34c50c5f4066bdee92b52953a9f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: e41040154d40a4a1cf9d30e436c000974d53c77aef0f98fc3162ed81fb274449
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: b493979435e0b16ffce31fc0ff590f31c1f6f3090a7369a87d60da5101e06b6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 9693a404a1da87a60578d3e431bbf979e78e810c26eb932df49ad8ef8f1c3ae2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: e44d9ac6713bc23c1bc7f27a1cc8f42c2b61f86a438cdf76d62423afa9607983
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5462
- `line_count`: 65
- `sha256`: 139df8653aecdb0544d05a7cae3b149db469ba2a009c9083fdf134e236f514db
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5462 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5328
- `line_count`: 63
- `sha256`: 11c2359e7000dacea3228c50c05078323205c2be91ac9dc50cdfbbd8166083b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5328 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5469
- `line_count`: 65
- `sha256`: a45210dc93980c80efbc997417540c45937879729089b23576a877c5fed57df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5469 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5468
- `line_count`: 65
- `sha256`: 0e4d4d6af52b950611fbbd3adae5e71d7b6f374e6e7fa0ff1a15960a7d596882
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5468 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: c18ed795ebfc689432185645c431cde9cedc4fcbfbb3b1a43f2023e73869c978
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 82068dad159e70176c105f25f3ac97b49120b9b762c76d403d31fdd8f6d90d58
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: ba2330a33e75b2d9af46f39dd073f42eef3630d8f630ec8555c827ebf5fe3a95
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 2ae5ca9e8a3a1fcc779a3437ff59a0ea2398ea434ce667f22fe42b0538c28853
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: e73b88e4a04306f5f53d4b4493e917f1dd4a91395aa11a7bc397a574123416c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: c9dc64b557b4bb0febbc430c23be65315c05e009f6182d16e600ffd83c52c151
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 3f7e578f3effda4645cb7ed054aa0bc6f17d1840ffe4a1fd94d9f3d88b59025d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: fa5e243314b1d964e0f3f3c2e6e2ad2ad2a4e5e8c4d153e06f2e4bde06ca92ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 2f90a5c4b474e2a6f9e8a3cefc25f74bb0d09bff460be6e25632cc7227278eec
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5480
- `line_count`: 65
- `sha256`: 21efeeadee6bafc9ba64a8da6300d5f0b73251cf8be0fcf23c1e0ea4b5c92a51
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5480 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 5c98a97ffbb56fd9664956ea95d007f0f3185bd72c1b0e6e7c1b3103afab6af3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5481
- `line_count`: 65
- `sha256`: 7373cca0559fafe16311039fd1b9d98a5de280a194210f8ec87695766971b2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5481 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: c017a0252037c5e2fe31a715885c14257a00bb9ab3488ed76b99f8e50fbdc046
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5480
- `line_count`: 65
- `sha256`: 9dad3f099e64da3d5a7c1081fac51edbdfb3e59d68f04fa4efb085aab6456771
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5480 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 4ec1cb00a05106353c5a961b8656e2b13b3d1a4e09d96ec9c3c21f267209877f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 493fd19027f922d6a3e452c54f4f4abdf8023446e3fb5f049608d8840331447d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 4be9c4a7e475f354676bf044daa6e161029931fd80c37baa869608f50ff0052d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 04440154109d716f7a574e0d68be18f663e36aa470b2b76817a51975641781cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: dd7eaf55153b3f828a5da073d9083e650bafffad05fdfb90e5d2d8f796fd8b15
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: b83d0d081e938bd7d97bf4b8cbdc6b35227325760d6cab192137b1ef318e8afd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 4891ab8b2fe6326bdc2670122ede3630736664b2034ef1e72f32093328bc049b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 0bd5732b7208d3c2f9c0b26fd5d911599d3d320503fcc5a58f3175cc9264e8fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 61d9438f0bbc6447d6c58938abeb2841b7a66b19ad62f303da5a75dc9444d871
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: ae9b4e4f8637b09c1554839b2b5b9e45aa890b2c0b60a689d619c9d0b0a21d6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 3ed65d797808c8aa5795a36363e1e7c32482011af93ef5875ea016bc2e1c5ec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 814107e877e76e198c78fa0982823c4768e71a9f797c9e9cb08d9c86612820cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: d90a7cadc8d70f8ca556affd96adae88f3a78bafcd9f239f29d3a38a996851c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 31738d219f550f430ec3e7131b470524c787cef9f0c02cb225be87b9c2c37605
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: c63f025b0c5fbfd76353114fc0ce06aeee02390f9d25d56c690167829f7fe162
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 217e468fabfc957120874d18e5dbb00641b0fc27866b2e9e2fe3a293d1e56901
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 8bc502811b59a4312d29c796028abb452a07a22873de1b0289767ae72274bf6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: ec6a17a07ab3a9c4c7735eeb358bce0ce3720ced72b42af0e719b4acda820c3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: eab060afbfd59affdfd46792b028d2b030e0d7705328bfece079ff8377842ee8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: f3e88697737bef4eaec22071187332f0973a6c5ea48c244d3fdaba640b79a945
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 4e8ee97106c5e79731187c1ac06ab826d3f5b472f31b01ae58d8f78deea48455
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: a4e9afeb425198be29077e51d18115dc54066172c0d7c16f5e5201a8f736b867
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 500535b9f11e71656e52c31d64218ffdea396faeda3b6b8227610d9db2798cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: fa96d13e7e40dfab1527d1e0b78416d3e4a154cd3ff96bea547a69a5ff2e1f90
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 2907fb6ea316c449f2bbc67b4acc1a1b94adc36993f39ef0b251e1b251bc9c4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 15a5de36fe1c6b21fe0a3a2ea2a91edb8e76394ab91c604290073d1415e9f681
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 8d5f1a2c41f291a4439cf6c59eaeae4aa152682836d758e6d7b72db89a3167c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 904af82bd1d8a057abfba2824ef9774757cb2648218bb8315e8798e6b9519ae2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: edb0a90005d130c7907f1ef8f23b7fce2ae999add59409588ab33f3982dde412
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:83 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:142 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/status.txt

- `kind`: txt
- `size_bytes`: 15462
- `line_count`: 310
- `sha256`: d17aa7f78eacdf2f78c6d898c52e028e5a6d1868fdeecafb0e5d420291f23a50
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 618}
- `summary`: txt evidence; size=15462 bytes; lines=310; PASS=618; tail=npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS rv64ui-p-addiw PASS tohost=0x00000000800010...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303/summary.txt

- `kind`: txt
- `size_bytes`: 15313
- `line_count`: 470
- `sha256`: 8c0e7ba3e35d38af6e02393ecdddef3fc85ad7f146410ebe645832eb5a8035a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 618}
- `summary`: txt evidence; size=15313 bytes; lines=470; PASS=618; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/core-regress/20260712-215009-1744303 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uzbs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-focused/bridge-invocation.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-focused/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: c717551e7ba3337a4d4eb07843894bbc3766b969e68bde41b61ae5d19176af9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-focused/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89274
- `line_count`: 672
- `sha256`: 2fec92af2fba93d9b45c488bf532dfc97e664a8f0c478d59e872ceff995b9580
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89274 bytes; lines=672; PASS=2; tail=.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/P...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-focused/xbar-invocation.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-gates/check-contract.log

- `kind`: log
- `size_bytes`: 271
- `line_count`: 4
- `sha256`: 9a07ff808ab19124406c5c781c3ccac463f375acf052e3de09e7be4c7dae34d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=271 bytes; lines=4; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=50 基线=50 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 50≥50 ✓） make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-gates/check-rtl-style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-gates/npc-build.log

- `kind`: log
- `size_bytes`: 48135
- `line_count`: 60
- `sha256`: 3bc41121b453f035c704715b4a0fed3bdc586ae4c7cc5ca5c7e77183ff24007a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__"]}
- `summary`: log evidence; size=48135 bytes; lines=60; symbolic=__0__,__1__,__2__,__3__; tail=Verilator 5.051 devel rev v5.050-35-ga5f4d4090 (mod) make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSED...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-gates/verilator-lint.log

- `kind`: log
- `size_bytes`: 8883
- `line_count`: 7
- `sha256`: 226472d8bc03f54ccf8e7854f166962dbfff1f068fab9c001267a908c2e9e11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=8883 bytes; lines=7; markers=<none>; tail=Verilator 5.051 devel rev v5.050-35-ga5f4d4090 (mod) make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/invocation.log

- `kind`: log
- `size_bytes`: 3091
- `line_count`: 99
- `sha256`: 3f29539ce27e3d8bd69353da978e1d7f172ffd214aef23f9b524b640d493285c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 176}
- `summary`: log evidence; size=3091 bytes; lines=99; PASS=176; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test - tool: Icarus Veri...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3131
- `line_count`: 27
- `sha256`: 77e982356fad6ca71a642cb7bdf664411e030b9c37ab75bce87ef26f77c82b2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3131 bytes; lines=27; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14816
- `line_count`: 91
- `sha256`: 6fb736de998e48cf84f0ab90c764e46dd9640e3d2d8812c110a7c122641453a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14816 bytes; lines=91; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14492
- `line_count`: 89
- `sha256`: cb5943ea83cac758fceec4a67961a742be7e3614c15acc1637138b6008037e54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14492 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: 5f399347499bc409c478a2226b1cae704a0b6c44d52563fb71e948980546d966
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17360
- `line_count`: 80
- `sha256`: a4b6435bcb69e5353facc2811fe4e6e9f8f6832cc19be52d1018111a3bb9047c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17360 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8629
- `line_count`: 61
- `sha256`: 41cfec95392b5abd6193913dd468b487a3188c125a5a318c38ff03d28a304ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8629 bytes; lines=61; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: c717551e7ba3337a4d4eb07843894bbc3766b969e68bde41b61ae5d19176af9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89274
- `line_count`: 672
- `sha256`: 2fec92af2fba93d9b45c488bf532dfc97e664a8f0c478d59e872ceff995b9580
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89274 bytes; lines=672; PASS=2; tail=.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/P...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 6239028902f3e8ec0a26df0b9ef979adbdf27fe7f50d9be13f31bcbfd841d08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: dd2eebc6d7b0b3d2ddad54323e21227330db14ddc9b6c341932a3870056e1c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17370
- `line_count`: 80
- `sha256`: 9b75855e42218972038f41a925f444e2766b62f19031f16fd632024732a55a52
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17370 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13729
- `line_count`: 87
- `sha256`: afd1fefafbf18033dee987085379bb4ca1c9eaf51411dde2e697c6eb3e5c62d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13729 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7248
- `line_count`: 54
- `sha256`: e9e9535f0f5921ab4a8bbe221d658fdf98e171f8f580b3c212d74c303922ada4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7248 bytes; lines=54; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: f594914716059ac375c26e4aa9f5ae4bad66b86e259a25a683a128b62235970d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 694
- `line_count`: 7
- `sha256`: 6b7d5423ef11199618478b4b3977c6b9cae3f9043498163520b419555b9edfce
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=694 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17346
- `line_count`: 80
- `sha256`: 27664acabfda43abfedc287eae986e5c1e00c21f3981fcc3443a53b184a97f00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17346 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155876
- `line_count`: 1115
- `sha256`: 57d8e3829508a912e0fa0f816fa3ccefa51ef4f9c22da2971c7a697c036df9ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155876 bytes; lines=1115; PASS=2; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test/summary.txt

- `kind`: txt
- `size_bytes`: 2944
- `line_count`: 97
- `sha256`: 69f161984fff1672afbb116fa8f36e049d7dbc630bec789f182dd9ec5bfd4403
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 176}
- `summary`: txt evidence; size=2944 bytes; lines=97; PASS=176; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-module-test - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_pipe_s...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-negative/compile.log

- `kind`: log
- `size_bytes`: 68956
- `line_count`: 655
- `sha256`: 2f60b25254637b6dd57aa79bfd4cb861ec6930ab8871b02d74af968a9ff0da72
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: log evidence; size=68956 bytes; lines=655; markers=<none>; tail=.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 word...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-negative/marker-check.log

- `kind`: log
- `size_bytes`: 2561
- `line_count`: 36
- `sha256`: b445694d9be7ec73f62021068a78d2702302aa85e79e3c9cd7973d3f2937a9de
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"ERROR": 38}
- `summary`: log evidence; size=2561 bytes; lines=36; ERROR=38; tail=[NEG_CASE_COUNT] 11 [DONE_COUNT] 1 [MARKERS] 1:NEG-CASE AW-HOLD 2:ERROR: npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1014: [IFU-AD-AW-HOLD] stalled AW valid/payload changed before fire 4:NEG-CASE W-HOLD 5:ERROR: npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:102...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-negative/sim.log

- `kind`: log
- `size_bytes`: 3940
- `line_count`: 51
- `sha256`: 8a64099128844ee2db5fc0e27cbb823e8203ce8a8043132d62f58cef724eef37
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"ERROR": 38}
- `summary`: log evidence; size=3940 bytes; lines=51; ERROR=38; tail=NEG-CASE AW-HOLD ERROR: npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1014: [IFU-AD-AW-HOLD] stalled AW valid/payload changed before fire Time: 45000 Scope: tb_ooo_fetch_axi_bridge_assert_negative.dut NEG-CASE W-HOLD ERROR: npc/rv64/vsrc/frontend/OooFetchAxiBr...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/final-validation-summary.txt

- `kind`: txt
- `size_bytes`: 2931
- `line_count`: 63
- `sha256`: a126ab7aade9429247fe70f57b6aca32795fe7e64db6a8713098ea45a996e55d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 12}
- `summary`: txt evidence; size=2931 bytes; lines=63; PASS=12; tail=IFU-AXI-G1 final validation (after the 21:58 assertion-only revision) Date: 2026-07-12 +0800 Environment prefix used for every invocation: unset YSYX_AGENT_ENV_SOURCED; source scripts/agent-env.sh Tools: Verilator 5.051 devel rev v5.050-35-ga5f4d4090 (mod)...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/memory-materialized/.github/memory/known-issues.md

- `kind`: md
- `size_bytes`: 523606
- `line_count`: 1446
- `sha256`: a01b1d1395c76beff7f93d11bb638558c0d070cd223ce15c7558d98f54d868c8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 14, "GOOD_TRAP": 8, "PANIC": 4, "PASS": 60}
- `summary`: md evidence; size=523606 bytes; lines=1446; FAIL=14; PASS=60; GOOD_TRAP=8; BAD_TRAP=1; PANIC=4; tail=�函数/影响内联。 - **修复**: 2026-05-21 已修复：默认 `VERILATOR_FLAGS` 移除 `--prof-cfuncs`，新增 `VERILATOR_PROFILE/VERILATOR_PROF_EXEC/VERILATOR_THREADS*` 显式开关；`gprof-build` 才设置 `VERILATOR_PROFILE=1`，`prof-exec-build` 才设置 `VERILATOR_PROF_EXEC=1`。复验 `VM_PROFC=0`，MicroBench 单线...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/memory-materialized/.github/memory/modules/npc.md

- `kind`: md
- `size_bytes`: 608528
- `line_count`: 740
- `sha256`: dad8b3b900c413dc8b66596b8110cd75f239ae84f24a52b2c7879c157af710a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"FAIL": 3, "GOOD_TRAP": 3, "PASS": 91, "SKIP": 2}
- `summary`: md evidence; size=608528 bytes; lines=740; FAIL=3; SKIP=2; PASS=91; GOOD_TRAP=3; tail=��。 - 2026-04-07: `bh_bt.v` 当前按用户要求回到“直接用宏表达式定义位宽”的写法：`tag/index/entry` 的位宽和切片直接基于 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 展开，不再额外包一层 32 位 localparam。这样更贴近当前工程风格，但文件级检查会继续报定宽宏参与算术的位宽告警。 - `bh_bt.v` 当前把 PC 的低 2 位仅用于对齐检查，不参与索引；索引来自 `pc[2 + BHT_ADDR_WIDTH - 1:2]`，其余高...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/memory-materialized/.github/memory/project-status.md

- `kind`: md
- `size_bytes`: 638879
- `line_count`: 718
- `sha256`: 7720d5198b18e0dcb6ee16c4d4ca3d72fa9f21b5ff0e304bfc597512fa4895ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"FAIL": 9, "GOOD_TRAP": 5, "PASS": 139, "SKIP": 1}
- `summary`: md evidence; size=638879 bytes; lines=718; FAIL=9; SKIP=1; PASS=139; GOOD_TRAP=5; tail=� ROB/IQ 扩容)。时序(数据驱动):除法器 logic-21%、DispatchBackend 42→39 级(均 CPI 不变)。基础设施:自校验评估系统 `npc/rv64/eval/`、Vivado 按模块 OOC 综合流程(4 核+绑核+内存看门狗,根治 WSL 崩溃)`npc/rv64/vivado/`、9 份核心模块专业 spec、`design/arch/ROADMAP.md`(时序 track)、综合崩溃经验。真实代码:Dhrystone CPI≈1.52、CoreMark≈1.146...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3131
- `line_count`: 27
- `sha256`: 77e982356fad6ca71a642cb7bdf664411e030b9c37ab75bce87ef26f77c82b2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3131 bytes; lines=27; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14816
- `line_count`: 91
- `sha256`: 6fb736de998e48cf84f0ab90c764e46dd9640e3d2d8812c110a7c122641453a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14816 bytes; lines=91; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14492
- `line_count`: 89
- `sha256`: cb5943ea83cac758fceec4a67961a742be7e3614c15acc1637138b6008037e54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14492 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: 5f399347499bc409c478a2226b1cae704a0b6c44d52563fb71e948980546d966
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17360
- `line_count`: 80
- `sha256`: a4b6435bcb69e5353facc2811fe4e6e9f8f6832cc19be52d1018111a3bb9047c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17360 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8629
- `line_count`: 61
- `sha256`: 41cfec95392b5abd6193913dd468b487a3188c125a5a318c38ff03d28a304ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8629 bytes; lines=61; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: f0ce22883b8f2a46e1a0fd3ad1be66ee77cd12257303b56437b6d8a2967b4224
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89274
- `line_count`: 672
- `sha256`: 2fec92af2fba93d9b45c488bf532dfc97e664a8f0c478d59e872ceff995b9580
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89274 bytes; lines=672; PASS=2; tail=.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/P...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 6239028902f3e8ec0a26df0b9ef979adbdf27fe7f50d9be13f31bcbfd841d08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: dd2eebc6d7b0b3d2ddad54323e21227330db14ddc9b6c341932a3870056e1c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17370
- `line_count`: 80
- `sha256`: 9b75855e42218972038f41a925f444e2766b62f19031f16fd632024732a55a52
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17370 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13729
- `line_count`: 87
- `sha256`: afd1fefafbf18033dee987085379bb4ca1c9eaf51411dde2e697c6eb3e5c62d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13729 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7248
- `line_count`: 54
- `sha256`: e9e9535f0f5921ab4a8bbe221d658fdf98e171f8f580b3c212d74c303922ada4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7248 bytes; lines=54; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: f594914716059ac375c26e4aa9f5ae4bad66b86e259a25a683a128b62235970d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 694
- `line_count`: 7
- `sha256`: 6b7d5423ef11199618478b4b3977c6b9cae3f9043498163520b419555b9edfce
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=694 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17346
- `line_count`: 80
- `sha256`: 27664acabfda43abfedc287eae986e5c1e00c21f3981fcc3443a53b184a97f00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17346 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155876
- `line_count`: 1115
- `sha256`: 57d8e3829508a912e0fa0f816fa3ccefa51ef4f9c22da2971c7a697c036df9ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155876 bytes; lines=1115; PASS=2; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test/summary.txt

- `kind`: txt
- `size_bytes`: 2938
- `line_count`: 97
- `sha256`: 9499c989c68d728d563e162bfe20a52eb26e840257a0ce35321ea28e79af2380
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 176}
- `summary`: txt evidence; size=2938 bytes; lines=97; PASS=176; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/module-test - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_pipe_stage_r...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/red-summary.txt

- `kind`: txt
- `size_bytes`: 1358
- `line_count`: 31
- `sha256`: 1809ee00853db514d885712c206c2e18520bba79b4ba204b629fa7c0a2577fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"FAIL": 18}
- `summary`: txt evidence; size=1358 bytes; lines=31; FAIL=18; tail=IFU-AXI-G1 RED evidence, pre-RTL-fix @ 31ddcb689 Bridge focused command: source scripts/agent-env.sh && make -C npc/rv64/testbench \ RESULT_DIR=/tmp/ifu-axi-g1-red \ /tmp/ifu-axi-g1-red/logs/tb_ooo_fetch_axi_bridge.log Result: expected rc=2/Make failure; co...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/strict-guard.log

- `kind`: log
- `size_bytes`: 558
- `line_count`: 8
- `sha256`: 3f46df05593da349cce166f3478b44c6b4c5041c2e1c7b1dcabe062ee7097bee
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=558 bytes; lines=8; PASS=10; tail=[agent-e2e-guard] mode=strict changed_paths=47 required_profiles=1 [agent-e2e-guard] PASS profile=npc-dev evidence=.github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain-npc-final-2 DB closure: - PASS db-first-audit candidates=5347 stored=5389 materialize...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/tb_ooo_fetch_axi_bridge_assert_negative.sv

- `kind`: sv
- `size_bytes`: 4720
- `line_count`: 190
- `sha256`: 8f09a953841f6ad43bc1942394d9aea7b4cd07735ad37484970c80d22af19bf6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {}
- `summary`: sv evidence; size=4720 bytes; lines=190; markers=<none>; tail=`timescale 1ns/1ps `include "define.v" // 仅用于 IFU-AXI-G1 断言非真空证据；每个 case 故意破坏一条独立 AXI 真理。 module tb_ooo_fetch_axi_bridge_assert_negative; reg clk = 1'b0; reg rst = 1'b1; reg mmu_flush = 1'b0; reg awready = 1'b0; reg wready = 1'b0; reg bvalid = 1'b0; reg [1:...

### .github/task-runs/2026-07-12-rv64-ifu-axi-g1-flush-drain/evidence/validation-summary.txt

- `kind`: txt
- `size_bytes`: 2729
- `line_count`: 51
- `sha256`: 17550702f12346a468936029a0cf879f6746d6baa6456156eafe64ab12b2367e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T14:21:21+00:00
- `markers`: {"PASS": 22}
- `summary`: txt evidence; size=2729 bytes; lines=51; PASS=22; tail=IFU-AXI-G1 bounded validation summary generated_at: 2026-07-12 22:03 +0800 task_status: completed parent_goal: active (full functionality and 200 MHz are not closed) ROOT CAUSE / RED - pre-fix baseline: 31ddcb689 - bridge focused compile succeeded, then fai...
