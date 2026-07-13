# Evidence Index

## 基本信息

- `task_id`: 2026-07-13-rv64-t3f-int-to-fp-fast-wakeup
- `task_slug`:
- `profile`: npc-dev
- `asset_count`: 945
- `total_size_bytes`: 7110931

## 证据资产

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359918
- `line_count`: 4549
- `sha256`: d8764c5c25d0cf29da0f7095059b043f80c8b55116abfd13c115bdc9e439a39b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359918 bytes; lines=4549; GOOD_TRAP=21; tail=c] top branch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000070 miss=390 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000080 miss=10 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x800000c4 miss=2 [0m [1;34m[cpu-exec.cpp:1600 statisti...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/npc-build.log

- `kind`: log
- `size_bytes`: 48082
- `line_count`: 59
- `sha256`: 3ed2b4e20e4ad3fb43dfef2882433b0229fe2c8297048b149cfe570e408fbb63
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__"]}
- `summary`: log evidence; size=48082 bytes; lines=59; symbolic=__0__,__1__,__2__,__3__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-breakpoint.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 759bacf90a27050b888263f901fd5eb0ffa9c3e8b10d9c2c1add856d31c28392
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-csr.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 4
- `sha256`: 64ea22733c1c648d458ed72ca058e8e6cab07bf1bb3a405c30194b124d72ea43
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-illegal.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: fe618512fc09c6bec94ec603c2d4669b6f9225895d1018c00296d4ae648e9453
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-instret_overflow.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c7eb752ddf7df2836c15e057636b2b3b066bbe61020cfa1fcb7667044ba4fb74
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-ld-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 10
- `sha256`: c44e62773c367801944447046f471368c167a7b46cc18ff61e89ced9b1e10b45
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-lh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 0a625bdb1bde894e591b08910e9c522dae78cacf6f215057e5084ebb7215469f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-lw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 81a2d0f7543c87aab91ea4ba7f6df69cb54772b8b02fc1970baaa2dec4813138
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-ma_addr.bin

- `kind`: bin
- `size_bytes`: 8768
- `line_count`: 11
- `sha256`: 43aba4a5ed598e42eafa14d04575df2738a9dc1b2262e599788408accf523041
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8768 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% �s 0�" �...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 6
- `sha256`: 23128cb88a441f0ec5b0aa92e3ff235468a97a94e292d35d9092ba02c0cd6d75
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-mcsr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c8ab2c5fbb9cf529518ebf007812028ad1dc524efde5bf2edfaa20c2b8a3df6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-pmpaddr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5c82f4f85902b25a1496ffba37f4338b26a971da939e6921985125def9242a2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: fab026d76c46c8506cb94a08cb632f2de6937d8b057204464e3e2cdc019780e3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: eb468050871ee3c797254f90c6571b5dab04bb018834af2c69265c0274a165b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-sd-misaligned.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: 580363d39fef7b89f9e2e386be8a7e60ac3fd56c1df679ebe3ed5de107573e9e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-sh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3c3de98bcf0acee9619646b0ace0b28ce19cad50d97d6323aeb3e30866219c48
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-sw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: e0715db1e4a9e3efd1784bbde55edb741d3ae50f551315ce987e5434a5683aa4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64mi-p-zicntr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: aeadca97e007d646ed5565e489bf1a0b805cfa321e996930effd2ad4bab21159
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64si-p-csr.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 5
- `sha256`: 2f7d31a97b4a1a8836b5b16b048e42d6d3be2d02275a1bb9e4810b27575a72f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64si-p-dirty.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 302f824e3cbcf3b842793355d42fdc5011dfaed03e59cec2ab8d1b4831766a3f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64si-p-icache-alias.bin

- `kind`: bin
- `size_bytes`: 28848
- `line_count`: 4
- `sha256`: 4557a25ddcb7abec27c88269b480cb0d7ec7fa64305725d29d8d3c0a52f7dada
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=28848 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �r �� �s�R0sPDt�r ����s�R0sP �r �� �s�R0� ��R ����s� ;� � s� :sP@0�r �� �s�R0sP 0sP00� �r �� �s�R0 � c\ � � � � s �r ��B�c� s�R �� ��� s�"0sP 07% �s 0�r...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64si-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 4f38f4a5a44b94c3317295c23666c5c5d6eb5d5aa6978b7de5509ec65f3ae17c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64si-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a27651d09a02b29a03a577555aa3571f8196280aa72cfd8baf0f3fd7b8778ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64si-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: 16442ae5360eef6283fa542a660128ff90f325c6385c4f14561403282e63b9d6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64si-p-wfi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00771ff518788f921c94a744180cc11a58d4c6867a7a28e02f20735727e41927
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 4150f7116a5d1ad9544d847f718a27dea539caa5cba32d9db43c0dd3a320cd58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 23ece6fcfa411fe3e9ac8aa2d73a60054e39446808a1551d3feb2c97cc438b97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 23d3611c19094402928bdffe805fa8532d82fd77c90420ad9dcbbf546b86a250
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 4
- `sha256`: d235961f7c7c03e9da495ec9a846dad59fd750a8fd31c7bb767a01e623f0b31c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=654 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 8474a0af82ef8d14cf5dbc04104d884ee96562d91ed90a22bc87d19350c99f12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 6d07c6e4fe8c1fd8b3f44f7dce5500299893ea370f733c6c7e01c48e4b288072
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: e51c2a9f92c0506b9df3f6c48a301a8889b7ac5b3931ac4dcba1a9b2fc2721d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: d5963171dedae952ba273fd6c4b0ef70b6f28a179dafb069832f8f662f963179
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 99b16ce02f59f4a136bb747ddfd6f2348748038875ad51e6bb0192e691402068
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 62379170ad5bb6cc61c4b4dc0ff7e91a9fdde586f642c6ccaee4c80eeb1f3d62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 7b980a18a7a0c0f1265bd180a9ad1db93e8c6cab0d658640d820cb92a3eb9b49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 9099de3acbff7f1453867efa55acba173e3f713d751107e9406a5e76a42fea3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cf030de16f0944357c4675d1bcd66e4c9ff80e240125f9290aadda6d928d2760
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: c4a66350fe2e3da52898d8665d719115bc88db0ef8aa4e2c93e8de5ed2e29de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: a22f5126c64613ddf6fd55ea6331fe76d4a0a0a982cbabc5cdd66da0ebc03e51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 237937babe46f052aa4697ccfa94dd5d62fe6e9c4f6ba2ed91df161b8bae8989
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3c5cb1679bbbbdb5587f3c2e0afb816204ec847dee3ec85268b44979b7dc56cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: c2afda182606f2e0a7e63e3474d5921c3aa8471978d516a44873e5c06b70a2ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 107d85d30c6e216d76cd6b59c73db64f75028be38ce1ee747124bff1d6ec90c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 1daaf37379469b4eaf41802fa680ed3c8c7bd6ce953df9c84d4915f239d4d641
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3b729d2c2d818c320db5ca4afe7a1f1348264eb2ffe0eba7ae1049417f20391c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3fb8dc5558e0ec98c7af988859a3cd3baca8da9aea3728df9d7cc85c7fd8bf77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 00b93d77799a70c2e3b84e597ee4c06a7fcea19dce219d84d8aee420edc53bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 8e0c3b0be49d00964fde252f04e3087506e0de98cceb587a5ab3066efb41ef58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 5338
- `line_count`: 63
- `sha256`: 04a999a2feccfd20f09d27e570f7ce57c0332692791b5837862808d0b09a8f58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5338 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-breakpoint.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 5567
- `line_count`: 66
- `sha256`: 00b5bcdb094c7c5c73c6409d0f96ec5b49584cc1ca0da9a57a2648341105aad2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5567 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 5723
- `line_count`: 68
- `sha256`: f3cad3c6479e4200da2593850118cd0a224206ef717daa373631e9b5569429ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5723 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-illegal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 5343
- `line_count`: 63
- `sha256`: 94d9f6089de2d798c82002417bd54246f62cd22704f0de6bad67ef8dd6e95a60
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5343 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-instret_overflow.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 5571
- `line_count`: 66
- `sha256`: cd3ce90b464dd7c571a5ff444907dd085d702aa126d27e616021eece09281fd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5571 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-ld-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 5342
- `line_count`: 63
- `sha256`: e40ef064b6f118a7ca34ba976a43faed5da8c4ecbcf980b5eaeac786efd6cedb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5342 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-lh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 5559
- `line_count`: 66
- `sha256`: 5f51404b757362b21e3059c29037d724925b8b964969ccd264dba745c2e7a94b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5559 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-lw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 5509
- `line_count`: 65
- `sha256`: 95c24b477030647efc5a70acd4d4cef4ef490b01d84dc56586332a377c78a18c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5509 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-ma_addr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: 2ce09bf3faf8788a16b0107636a64fcfeccd56d1abf3d885d3cdf72f7a7eaeea
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 5404
- `line_count`: 64
- `sha256`: a7c998bbbf35f904c96b934224ef916d7a59bda982094b42010f200ef0c9e39a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5404 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-mcsr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 5395
- `line_count`: 64
- `sha256`: a389cb22d459bf07004e73bff65a0e7c26fa9ad4010f8f284aba7e7ffde954a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5395 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-pmpaddr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 5078
- `line_count`: 60
- `sha256`: 1fdd1a6d380e9a3c24d43ad816e27f8304656915b19bc97635c44d09172d22f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5078 bytes; lines=60; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 5258
- `line_count`: 62
- `sha256`: 2ffcbd2d9c6ed1e69f261685467082f832b52bc08a4fd2fb8c88fcbdf8952152
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5258 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 5504
- `line_count`: 65
- `sha256`: 36ba9c034b00f9b056c99690d6e53952c7ba2e681318c98a0f02fc36ce1558a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5504 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sd-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 5418
- `line_count`: 64
- `sha256`: 7377d391376b25901916317c5bde6a1adf7baf2d2ae0894b3738c54ca6555b58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5418 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 5426
- `line_count`: 64
- `sha256`: 1d27c096bdb102dbaa284ac163dcb1ab4103ed826f8424d3bcdb4833f40ae79d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5426 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-sw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 5414
- `line_count`: 64
- `sha256`: b082006ed7585d5e2d4899eaff60a249c28e5d1dc16a08c00a9afa4bdfdf07e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5414 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64mi-p-zicntr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: 3e03d1aeabbf2ad20a10c163059d3058d9cd70122a5442acb9d88c0007310c0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 5570
- `line_count`: 66
- `sha256`: da4f69700ba8bdf5b19fc2cc31039dece499b903ed347fdbf7f8f01a250daf6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5570 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-dirty.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 5445
- `line_count`: 64
- `sha256`: aad7a262194d919e59ec4594e87d75646e090ad9f5374b13214a9baa0961fc7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5445 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-icache-alias.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5488
- `line_count`: 65
- `sha256`: 3c522793a287290c4fe44a8e7d083b4df1eb68cf79753622a219175f4947aa87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5488 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 5147
- `line_count`: 61
- `sha256`: e115e12866d68733f1eb3851928787834f8fd8b3b8491e250b052ead8af4a986
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5147 bytes; lines=61; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 5617
- `line_count`: 67
- `sha256`: 38c6dc348c0341cb40e779d350b2be5b8b93b4ab1a03c44947424c00611d099a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5617 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 5322
- `line_count`: 63
- `sha256`: e33d3f94572e5040cf48297fc0c4bdcbec68f0453db7e5fd3c91bff8fe7aa27b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5322 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64si-p-wfi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5268
- `line_count`: 62
- `sha256`: f8ec09a60b567dce0e4cdc03f5d005b346ce6074a6c10aff9eddd8a3fc2ed30b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5268 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5338
- `line_count`: 63
- `sha256`: 94aa601ec3db4794e2f7d5d5dacf36dedc3bd695231d18075de376d4529df428
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5338 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5267
- `line_count`: 62
- `sha256`: a025b2b1a9ed759f725c598627f7ca24f6845c67efcace4db5db1fc86aaba442
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5267 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5267
- `line_count`: 62
- `sha256`: 57c6077fc19c77eff20e5ff9725df11a7f92e6ea167e63de8af4d121ddd2d1a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5267 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5267
- `line_count`: 62
- `sha256`: f14584a6e92f3492214a9a2d61b9257435dad89a11433d6d1f4be9fd3cb24b0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5267 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5211
- `line_count`: 61
- `sha256`: 059fcbc8ccb9f6556a38c07d4720a903c471a1ed774f90f652c5cd9adefa92a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5211 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5268
- `line_count`: 62
- `sha256`: 0365d255685b506b70394bbb4bf24d8a64811d6a0baa921c28df119b955b1fdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5268 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5212
- `line_count`: 61
- `sha256`: 763ee1b1eff975da7b0d89a01fafeaafa6deee35ffab8324b5ff1d56dc28673c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5212 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5267
- `line_count`: 62
- `sha256`: c8ccf698d94296dad827ad4f4734d4ab36a619d5ab6b40ddce0541253374e950
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5267 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5211
- `line_count`: 61
- `sha256`: 5d25b2796fd4cbb1b305715d1b4810b6671ba83fd0414e7dcdaa58edb193a523
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5211 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5268
- `line_count`: 62
- `sha256`: 733ac98b47273a1651efff213a1b2a36ea25cc906377e066acab83b6d11754b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5268 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5212
- `line_count`: 61
- `sha256`: c8ed32a52a79eb5548dfadad5a4f6aaeb5a5bae923a0de8363a8cf565873c56b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5212 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5336
- `line_count`: 63
- `sha256`: 2785096a5a3df6141611c663053b0cf9cad16ede8fbff6ef8ea0bc9704a7e242
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5336 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5336
- `line_count`: 63
- `sha256`: 1165697c10b62b893dd38322309fee4feddadc871652d7d53556cbd90d995a3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5336 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5268
- `line_count`: 62
- `sha256`: 6199af07e8c72de637e34887e236684c744e1ba1ef54250f321500d38b129514
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5268 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5268
- `line_count`: 62
- `sha256`: 8f987e337079a6c9229c34861ab0ac71d7518eec401bdf535c00df58d73f5f1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5268 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5337
- `line_count`: 63
- `sha256`: 24349c57bd421b6bebc4939f3ea7e1b537ee7e10562045658b34ab2c6b5daa52
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5337 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5482
- `line_count`: 65
- `sha256`: 113d19e5391cf5a248989f1a63f7dd560906d5f61defa0ece6942341a1abbd03
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5482 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5638
- `line_count`: 66
- `sha256`: 51544eaf32afbbe428ade27d8bc4a24afd3dd132f672ae9353d2a75fdeab8361
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5638 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5644
- `line_count`: 67
- `sha256`: 28ec926cbd7563d2806df92f36148e3c495b23e50ee56f62dd8ffa53d38f0c14
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5644 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5429
- `line_count`: 64
- `sha256`: 6ad66b204a9a010d74e3c377e49d5e91e34b7b4388abec32a60ebd873319357d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5429 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5481
- `line_count`: 65
- `sha256`: fa05664a3aff1d17200d823b22059e93945ed8c212adac38ad54b4ac0f3ac140
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5481 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5499
- `line_count`: 65
- `sha256`: 977fd5bf17485f612ca5c6915b9929bec578c4af1a8824f8fe33447136e6d4b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5499 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 31deceee3cda962bcbea502367e480552663c0f2b4bb0662345e578c1a37213c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5514
- `line_count`: 65
- `sha256`: 9d4133dcdab68705aa9b63332665bec9df736e46128390cc3231dd18cf72e4e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5514 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 29bbed6dd937efb28be1e13f41ffeafe990ab96ac0f34542c18b416be303e9a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5500
- `line_count`: 65
- `sha256`: bd2fae8c8db2c21f23af067058217f281e44ebcbe715019b7a3b551b3219f488
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5500 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5502
- `line_count`: 65
- `sha256`: 37164ff3ce8d3d7fbf2e0910788768341c15239cea39362bd692c237f4a4fa89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5502 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5345
- `line_count`: 63
- `sha256`: c1599cc389fbe3f292142a652617ae19f518bcc3d5147abbc9a89c3b893e22d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5345 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: 3b24c7878451a1ddc1ecd9d249b0129b784ee8785319655918e286a8b867e85d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5212
- `line_count`: 61
- `sha256`: 0338d22b3f92747be7a87d2bf114e40a9f64163408df4b2727814b4d41bb9aff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5212 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5633
- `line_count`: 67
- `sha256`: 969b33f65f4b1a4589abeefc945f575b951752dc1d41c6b0cbd33e02c6ce86f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5633 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5430
- `line_count`: 64
- `sha256`: 3e1f12cd197d229212da06b23e4925569f95fb1832beb261ea1bdb605734211a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5430 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5482
- `line_count`: 65
- `sha256`: df1a730b03f1fee1cb1e46007a109a2522a804f490a9bdd215582ec372e522a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5482 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5501
- `line_count`: 65
- `sha256`: f4a6550b9d7f9a667eef72301cdb95b4db055534482cec9520bcd40613dd4e98
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5501 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5351
- `line_count`: 63
- `sha256`: 69fa1c7313d6e6de7d9a830684060e524485f89dacae13eb575842a8f5162daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5351 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5510
- `line_count`: 65
- `sha256`: 8d2b28db420dbc17d452706b318ce74c4700b801a947c224d865c92dc6980c5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5510 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5497
- `line_count`: 65
- `sha256`: 42b5a694f06704fe349b0db8a8a518a34497142a02d58cc191ab591d7deadc71
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5497 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5501
- `line_count`: 65
- `sha256`: 133bf84bffed76c56a8f92f2610cd93ba0b80723657bc3c34fd64c3a9bd379b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5501 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5501
- `line_count`: 65
- `sha256`: b94b46e7bfb84cf2b34879f18a17132a183b3e8a50b3ab16379d90134d3d3c87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5501 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5269
- `line_count`: 62
- `sha256`: 77011fea2b050a846ece15a28d5ac3409a9f3a3a94ae0c78a28803a3b965daf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5269 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5489
- `line_count`: 65
- `sha256`: 98c67fc2d6dc3eadc18aef257a74904d8b4a0378a81247a0615a55dd11e25aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5489 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5276
- `line_count`: 62
- `sha256`: 9bc654a1e291439069fbc5da298a7986cd52d9a8c6a0617fd9c969ea077ddf2e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5276 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 8b740029a45cbf295ecc2f36415ffe45068cccc9a32e860dec1d2e80669746fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 745ba57377c194c822d2a56f4bb89e33b2a5c1cf7ee0799779798d9419fc5b52
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 0490265ee9fec09facb35934cae60155f5dea813a17e1d97a8f853daa76cf105
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 5e1d956a752ed698f05d2f7a25adc3f82a95f18802de343204f5c50d24c6e897
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 7a75644fe52635ebe8d12f058421494754433e8f4d577efe52da7fa65c6904cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 14312258a604dd5083da1d8338ed0d62e89b1a538df65af4d105966240739fe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5261
- `line_count`: 62
- `sha256`: 7da19e2e46a8523e4c75aa8a3d0af75cbcb4c011ffddaf005b3e7a1abe7efe9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5261 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 1698c4590b4db1079bff01e916a9f35ddbfa490fd79970f393c7c4387594aca6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: d7739f33d7086d119850deac31f7aba9fbcf79be5c551fa1f31b9ab4a5a383b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: d148a2a7ddbda6bd8a01a76ec9e7e761dd697694283c38a544c3b7a57803ee74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 4dbd73bdf1a2a18338a4429008c3bc6e5657ff96b68e857350e56276931d8167
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: d6253afc432f30afa743bb8d4f8773ef329b1b9cc3ff67b5de6455ca20ab6f5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: f8d65b0ebe25021ab7296d9164abd5e69ac5140e5ffe92d9a74380221fba262e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5511
- `line_count`: 65
- `sha256`: 8fdf82fbce894dacd78d92aa14072d619296f7ed450bd83d7cd891992a6e427f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5511 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5251
- `line_count`: 62
- `sha256`: 83e88812d2f03441bec55ead0a7ee26db64be40c086875701462fd584f55f583
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5251 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5562
- `line_count`: 66
- `sha256`: 4701a54379d1b79f052edeea89950f54c6099d4afd92e74f3d72670b2130d9c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5562 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: e6f332b4dba66bb3c2329c8c71105d1d8388fabd5b8668ccfd6d4c4af490a7f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 40ef4b952b0e5c8234da2b0ac61eaaf0a1d2098bfc0e79472caf2574416ffb62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 64fb89731df981f56fa2488af67e335bf5577584fbebbd359233a3ff3788ccdf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5750
- `line_count`: 68
- `sha256`: 050cf4f3c97307b8e37823a90dadf9cebf9008a48c22d92ce5780aca3900f878
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5750 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: b2dae1a781b89d71a457c68373d3db2beb4c89e56066cec5036fa554671891d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 047479428fa7092fbe621f1cce30dda253f92f62516bcf9b9da639f8fb18b952
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5330
- `line_count`: 63
- `sha256`: ce706a4d857880053100cd9333b37a3c22593327498bbfcbd323ae096c96c7f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5330 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 9f32cb8a26f3a3116faff3afe7c117c7296914f934eafd7e9dd46e0ed34f545e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: ac1b141776cebc4b4a842ea59817e812d343c1f0ae592669565c1359063a8d93
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5765
- `line_count`: 68
- `sha256`: b9a59b55f3af570e40a987c1112d3f8770523f3f005e9c5ef6efd3b9469d7184
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5765 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: aefe94caab6007ae97b5b058eb6705554157486484c57a275e9f0888f4d4924c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 1f73ce7a9c179250dca6c08116326f78d4cefad858c22455133da81bbd1ddc47
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5717
- `line_count`: 68
- `sha256`: 70be86b382b4acb86617d19da058003a9a571d784c487bc551c2565fa0b733c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5717 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5719
- `line_count`: 68
- `sha256`: e0a72e66518915f929870dfeb15c127bb76d200c8fdd96742f923f160d363891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5719 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5719
- `line_count`: 68
- `sha256`: 989acfcbc53e5fa298645dd9f607249f75ce065812ded4031f4c9e90119548bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5719 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5180
- `line_count`: 61
- `sha256`: efbf88b1abadea90cfb93a691dc010375758c5d5ef3818bdd6b0807bf8a5fe79
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5180 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 368d5db88fc644aac06aebb3e7bfc8ae935ee5ab8e812fa1b3796a927af3c62c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 2eff099775541f602a99be5fbe421a64eb96de51687d90d5d01d1ae7e9c9cf09
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: c9683ea64ac651311a88468304e9e9c23c6c14f570c18f921d8779943d5ba8ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 52bbce6d16df9aeb7b8cd0f2fc7d6bb415daa7af8818f696b8c56bb5256ba565
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 5b92b8c7774c765971f82cc730f40348b6d076111e16782f3a72fdd202b73200
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 1f3b74897c81342abb8b429897df0de33958dfe990cfac3417864ec3a90f79cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: a9787e36b889c0eaa0cb8c2787ab936366da9bcf8745c48c30c643be9779f185
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: c98e01fbedb9b103d34dad75dd9cb9905c538fd4d5013227f4ca2eee5d6c6c0c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 13de990780363a0a84a4a4967ed5aab4fe5de0c3a841e0dbbcb13936d0135857
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 8c2378514da14c0261c387b5ebd4485123668bd0eff1abe688c7c789dd0df2b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: c72ddda4c5f3bd5f091bf1a9c704f66e3dca837c9188132e322bc5174cbf57e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 318aa15d7d69b2ba3b63074139e27d7eef8216aa043c0df09bf3d34dc087917c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: a29d094eaa87284ca1f9e964ab086b8517b31004b156bcf6d2c51fb89124a565
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 2f784fdfa692d6a05f9223c15e6cf1de81f745ad3ac0042b2ff0fb5ae242a9a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: ece6c52e44e2ab4d14864cf88bfe3c8f1ff2b1165e1bab69393a4db92db28f54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 8befbf83baee23eb7efba83490eef4ddf6c181c5672626db1bd2f2ff12b53b28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5511
- `line_count`: 65
- `sha256`: 9f8c1544a27b32d0fcc89b833add1c2c8d542907ecd95a3f326004eacda19d0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5511 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 19ad1504de5e672306c3749123a009e5ccd8f496e0ebf5072a04e245ab8ebfce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 202b8d1bb8041058978d42487df2ffeb5d56251e99976b301e0fecb0d608346d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5719
- `line_count`: 68
- `sha256`: 26d52fe581e51d4c1127180b1634d31e9b8c007fc35b9c61e21f380f440e1aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5719 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 66a0239b86c7097617afb24542fd51ff3a1cfec32a1e63a2c3ba109fcfa255fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 8fab8261669915d74139b69fbe18b601a4da69231112e7a97576bb0872f714ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5340
- `line_count`: 63
- `sha256`: 4158effe392c94f3f81d8e62b94724c51fdf81249e1c046a8622aef1da45bf9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5340 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5477
- `line_count`: 65
- `sha256`: 84e1f68070342dcb03c55241ad352230fc480e397a064cf6a08268c57018b5a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5477 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5343
- `line_count`: 63
- `sha256`: 4c02db4bde62c2062136ed8995b210eac39ef0c245e3d6f2a241998cafeeddaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5343 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5479
- `line_count`: 65
- `sha256`: 46d2203193dbaf5c4bfa5befac93446b2b8e5ad854bdb0ebe474a6de714635aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5479 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: f9ebc10dd42a71eaf31e3eaa5dc7c123d2ae16a7a49ad1fb166476e566f8bce3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: a23bd7afe5d032f9e579ef6b41fb8ab77cf757111191c98bc5e856a2759a17bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 5af092bfb6c189383329c901ee3f37f349c0e98f8d1cee4f3b66dd804f6e2af1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: e6fb7e80fb02e7dc05836491b79cbadf2aa0051a596dd1f31771b110b320f9ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 8de449f71e48b38c801ea86ddf06e1f63b960836e5308f7f3bf9b8176946d17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5475
- `line_count`: 65
- `sha256`: ab940c6a3f317b9f9dc9db0823824522414e744432c8deb10bab0a43958fcea5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5475 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5341
- `line_count`: 63
- `sha256`: 5c1c12f174662e23e15b28829dc3d5563fb06412ca8ff2073a979c678aa706c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5341 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5477
- `line_count`: 65
- `sha256`: 24815046ac4bfecef3f60607f43f359d81f895309cd15747bbfea537ff8d1ec3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5477 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5479
- `line_count`: 65
- `sha256`: cc71caa199e691f9f679724707bb0d8981b25a066a72b5efa642cc105dbf41ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5479 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: fba88f886adb3090e4192c123857a472a20199fb00cb58b7819e9e31c82b2c23
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 49311d42cc1d65d0dae7e5549b634798ae9f021fe0244ee931884f554ac08327
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: 18adcacf2473a42b1034fcab26c8bcbd0cf77a2667a11cc1a056914c2d92de8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 0543378bafc223b4b12e5b3e1ae38fa60e1cf8fb532ffd1e7dfb79ab4eba0621
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: 621c1dff71dd5c188d029e6a490b38d081a3223a0862de047f40f75c2e1eed70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 27fe24bf5ad0631d6bfe38d9bc3a63d6d05f07fc6876c5233ad7d122b2002fcf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: e6701e80e86ff05cabbe44f3c3cd8287bddd2be24d2a9261d7006448142a437f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 4b24bcab19c1a6350183f81c55a29f6eafbf2d9d4eb97e3807995948775ca5d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 72f0cd7af10cc09c0b666517713b855052bcf4ee2840e77fd5bb96515eb25c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5493
- `line_count`: 65
- `sha256`: 021df2417d70df4ae2eb7a2c33de73714a884070a290d2dcfe0a4e3ada4d0322
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5493 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 660f1d2aa24c8e7c60b04d6107a0457b8ca51f35c9a2966bc8132c0ab5bfc7e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: df3e513aa5914da30e34e117a32530b81135a9c32de3a7f5366177c8a21cf3f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b91ae7153d3c3d6822fbc1fcfe32355ab78546e008debb449872fb869974a111
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5493
- `line_count`: 65
- `sha256`: 4ffa635d0c0992d578c7097df72615eb8063cbb485fdccdab7154b5a30947fe0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5493 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 6137a51f1f36bc0e925e8e8b7faf30d217da208e0d4d20a649034bdb02e1d868
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 0b2cffc9acaa35dc79dd9a65e02fc365a5a270cdcfb539abc464b99728c83f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: c1da4e8197be8db3af3c4bbee0cd4f98dc5e384e076b9470f1a308376fe6b7e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 16e1f19cc9c8e0562242a4f3aed1ee2eab391c8c99bf0dfec5e99cc5fcb28dd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 2cdca9402851d37e2b75cae27d0481579675156bdb53e527935d1f98f393165f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: adda8cbf3eac9eb22ec0c5984197123d3cf412b6e387096936ec8a0b21984c60
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 777679cc44e2a8f22cab1ce4bccf78cbb63b9f2dd6a582975b420472e79d92e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: a24047db191d58aea49df825507f83f9a9a2f0b4d76d0b48a919c8cba6195273
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 13da5fdc5f0776192fa317cc7e595ee608274d62dcf37b3d699dc51e7ee84836
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 3e8398605275ec7f164ca5757aa66fddee623f400696383001b8089890d72a59
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: e7328d721e5bad95a3418f2e1450e29d66c3fc23dbea8f614272c298cf262ba0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 56c37f6d034af08eaf7bf4a56b3c350ef8d2c2f575260d5b3465de695e0c909a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: cd4ff2ba1bbb5a9f48888211b2470ab25b5f070d5633c65a2757f291c2df1c02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: b726b143e1e7b11c5fc0d238d1339fe9eb3662d9fc454e4c037b62dbfdd6c1d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 0636945846342f2f1e3227b580f58cbc4c286d92731eafe06c47a23d4be67265
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 04e7b3f0e55a3ba7792760df09bceabb807684fbf86140e83a48970d9177ef0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 9d003543af88541311de59e16e86017c607fc2ba936f6c73c47c9071b6fe1649
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 18c171acc16fc0278ff9b4a0242ae79d19148553243d8d77f06386f9bbf53045
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5714
- `line_count`: 68
- `sha256`: 7432c5867339ce1b7c1fcfbce5eb4768e4b32cb7f822e6d9e3ffef6ec7944904
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5714 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 011277df32aa3ea888914e087d3c84beebda44bab994d48d1b5d490a65a6ae61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5714
- `line_count`: 68
- `sha256`: e66971f7fb3cd35473200bf0bd0f8486a43e8d7e46d063974d02d3ebd46c5e4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5714 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 171c9687cd74827ed061b9940ac017939fe58c496f69b1bc773935925b53c6f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 8c5962cf3d43e14def2a8c403c97064a792e0232bc58f05347aae3bf29f50417
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 29f78b65f20ac078fa21a112d60ce09c54e782ece43df5f2ded084d12ef0629a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 3fe4e7e445c8e71c4468fa1bc769ceef786c9276109e6ac65b09f53932df4699
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 2988008baa44ccd70784a1495bb679250ee5aa0e3459a06533bafb0aebe46181
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 6bff0f14b12d3ee724734d824df2435403bae7077cf2d5554a0a6012c94d6af5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: fc98f5c4c312c5c9c46794ec32a832e2010d2b5dc7f9065e2b52554388341dd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: e6560bc22ed8bf48d136c0475b0c5381d9dd2f845bb094d0e8321f49339ce405
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/status.txt

- `kind`: txt
- `size_bytes`: 17885
- `line_count`: 358
- `sha256`: e1aa30eeda8f8f0ce9c2c870d4bea46343c5d186f105b0f55f4355d8ed17cfa9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 714}
- `summary`: txt evidence; size=17885 bytes; lines=358; PASS=714; tail=npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS rv64ui-p-addiw PASS tohost=0x00000000800010...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115/summary.txt

- `kind`: txt
- `size_bytes`: 17874
- `line_count`: 542
- `sha256`: b626924de99de2098bccc670ce350ae21fd8d3f165c7d78706fbc9abe7827661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 714}
- `summary`: txt evidence; size=17874 bytes; lines=542; PASS=714; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/core-regress/20260713-112031-2033115 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uz...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/coremark-attempt1-missing-env.log

- `kind`: log
- `size_bytes`: 500
- `line_count`: 7
- `sha256`: 06b204174c01b2fd21704b5ac2c6aba44966d6dd4a326b637f388bf4712e3911
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=500 bytes; lines=7; markers=<none>; tail=Script started on 2026-07-13 11:23:00+08:00 [COMMAND="make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=10 run" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' Makefile:5: /M...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/coremark-iter10.log

- `kind`: log
- `size_bytes`: 8196
- `line_count`: 103
- `sha256`: 85ac7cb77513ee4e2d06a2d5b0224b307f4c721b4077d7ed20dea74aa8af53cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=8196 bytes; lines=103; PASS=2; GOOD_TRAP=2; tail=Script started on 2026-07-13 11:23:10+08:00 [COMMAND="make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=10 run" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' # Building cor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/focused-final/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3260
- `line_count`: 28
- `sha256`: edfe621b6b64150be094c0521e99d43f59d316e787b6ca02053878e01f822b76
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3260 bytes; lines=28; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/focused-final/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15277
- `line_count`: 102
- `sha256`: 380d66b06d12e19565d60e80def738762286d77dda09cd435743e9ef48a78176
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15277 bytes; lines=102; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/focused-final/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: dbc959eb78157c171a948166cd967c09380ae66570391575b04b76ab6957f17c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/focused-final/summary.txt

- `kind`: txt
- `size_bytes`: 278
- `line_count`: 12
- `sha256`: a6bb405bc9caa774ce6e7fedc2a060c45ffaba72460b2484df06fbaf6dc1a019
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 6}
- `summary`: txt evidence; size=278 bytes; lines=12; PASS=6; tail=# NPC single module testbench summary - result_dir: /tmp/ysyx-t3f-focused-final - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_ooo_fp_issue_queue - PASS tb_ooo_phys_reg_file - PASS tb_ooo_int_backend - total: 3 - pass...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/reviewer-focused/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3261
- `line_count`: 28
- `sha256`: 4c8eb65b32ee595b37960555989063c35376c9ac6296817b832acf3c5b8a6529
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3261 bytes; lines=28; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/reviewer-focused/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: 6e8b03051f6459e31cca0e186e2c3f11127fd8fb876bb0dfcb212767b79303b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/reviewer-focused/summary.txt

- `kind`: txt
- `size_bytes`: 253
- `line_count`: 11
- `sha256`: c2887694c85b7dab4745319ac1da572fc19004ba9e21b06862e555a02ec908cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=253 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /tmp/ysyx-t3f-review-focused - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_ooo_fp_issue_queue - PASS tb_ooo_phys_reg_file - total: 2 - passed: 2 - failed: 0

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/green/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3260
- `line_count`: 28
- `sha256`: edfe621b6b64150be094c0521e99d43f59d316e787b6ca02053878e01f822b76
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3260 bytes; lines=28; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 2b3d5082fd228d3095d3ca6159a9b3e01076d0e03eb96d662c211bd32f634c10
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /tmp/ysyx-t3f-module-final-review/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 405
- `line_count`: 5
- `sha256`: 1b0e2308a3192ce19b8d24b40eab41db4c47e7e9dcf7873205d13eaac0ff7d75
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=405 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /tmp/ysyx-t3f-module-final-review/tb_axi_clint.vvp /home/lyg/PA/ysyx...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3503
- `line_count`: 28
- `sha256`: d3a1892af4431e6e09424f53f221b8671044ac94b13f258a4b0c0592252d3203
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3503 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /tmp/ysyx-t3f-module-final-review/tb_axi_exec_firewa...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 399
- `line_count`: 5
- `sha256`: c6536449dc2602d509154f60cab22a75f99c0e1033c08a711cbcae545228eaf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=399 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /tmp/ysyx-t3f-module-final-review/tb_axi_plic.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: b0a54a108a9dc5d13b6bd228a6c0d495154d2d8556ed0b81d43bf4b4d1e424c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /tmp/ysyx-t3f-module-final-review/tb_axi_to_uart.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3282
- `line_count`: 28
- `sha256`: 52a3ecc93b461b3708ab072873b19e41ade054da1c085e6bd2f0c30f710dbe11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3282 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /tmp/ysyx-t3f-module-final-review/tb_axi_xbar.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 400
- `line_count`: 5
- `sha256`: 8551b508ac4ffd1f912372e483e20bf90dbbb0056aca2697548fc30e3be7da74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=400 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /tmp/ysyx-t3f-module-final-review/tb_compare.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 400
- `line_count`: 5
- `sha256`: b75fdc3c0fdaac8f717c2a0de8b30575aa9463896bcb1b52752aeefbbe570cff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=400 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /tmp/ysyx-t3f-module-final-review/tb_csr_file.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 544
- `line_count`: 5
- `sha256`: 99bcdc2ff3d4e4f9fddd591ac41ac2f57d53a566077bffd2c2811ad3ea8f8d08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=544 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /tmp/ysyx-t3f-module-final-review/tb_decode_stage.vvp /home/ly...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: c291a8e7296eb58f1671729c154b278b53bc4d21177b9fd991108435b8f96f72
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /tmp/ysyx-t3f-module-final-review/tb_decode_unit.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 389
- `line_count`: 5
- `sha256`: 347a8fc0e5ec25507770de66e4525c4e0b463b043bfa2ef702ae592207635ae8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=389 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /tmp/ysyx-t3f-module-final-review/tb_immgen.vvp /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: ca3609d9bd4a06ba09d09fe88b23e15c043e76ea234975a9c055c7af838a1737
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /tmp/ysyx-t3f-module-final-review/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: bc00c0339ae3b03eba3272b56d149abbc7d770f352c62a946c3f14bf7e1d9475
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=418 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /tmp/ysyx-t3f-module-final-review/tb_lsu_control.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 424
- `line_count`: 5
- `sha256`: 61313f637cacbc979b139d9facf2ec9cbab199ff6225da9be11b263e218813c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=424 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /tmp/ysyx-t3f-module-final-review/tb_lsu_datapath.vvp /home/ly...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14552
- `line_count`: 89
- `sha256`: 3dbc673adf7269ce2ce1351919d83cc995ddf9398106e4e3b327b39f8036e845
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14552 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/ysyx-t3f-module-final-review/tb_ooo_alu_core_...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14228
- `line_count`: 87
- `sha256`: c6e5855e6f302a3a1f4f58a70fd29a3e773964668ffc549dd29d18200be13f7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14228 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/ysyx-t3f-module-final-review/tb_ooo_a...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 424
- `line_count`: 5
- `sha256`: 9fab4c68639270f3b32aadc6280174bb098cd924a5817b8aba563e6ade0fba80
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=424 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_amo_gate.vvp /home/ly...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: 7410af638a587cbf7edbe1d97170c532a649c357bfd66b732aa9d6d0b81b4676
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /tmp/ysyx-t3f-module-final-review/tb...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: 63550aad8f41314e3beabac56e658c0f4e2a0a7b3d1606cbd2f160b34612419b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_bitmanip_ga...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 881
- `line_count`: 9
- `sha256`: a790e5fa1d838094c7dd79f59defd82e1068a4731c96a97e8d4710d02108c042
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=881 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /tmp/ysyx-t3f-module-fin...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 836
- `line_count`: 9
- `sha256`: 607d06057f66fafc0f28168454c5407fa20d1b70369a1fdb21b50fc4fbdb13d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=836 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/ysyx-t3f-module-final-review/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 619
- `line_count`: 5
- `sha256`: 8fb990a4450c15d4568aab6e5305f95792c90297e974ee3e788115eac1776740
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=619 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /tmp/ysyx-t3f-module-final...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 891
- `line_count`: 9
- `sha256`: 36f7987e8f025e1e594485063699f172b7f167a0a8ccd8b3ee3f166608886466
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=891 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /tmp/ysyx-t3f-module-f...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 5
- `sha256`: 34c61663eb181991c3f64bfe77efbfa9cd1783e208f3c900e951f6d10a7e86ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=491 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /tmp/ysyx-t3f-module-final-review/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 576
- `line_count`: 6
- `sha256`: 9cd6471d920a94fd7686304bf06c7b703382bf48d68b1a3e21bfc3bdaefffc3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=576 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /tmp/ysyx-t3f-module-final-review/tb_ooo_busy_table.vvp /h...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 54d42656af98b2c7a03d81f44777bfe3e2d7dd6c37ca154122830fbd0558947d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /tmp/ysyx-t3f-module-final-review/tb_ooo_clmul_unit.vvp /h...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 794
- `line_count`: 9
- `sha256`: a0eb0c45a1eb94244ca49af3172fbc17ed0f7054a66b6ecab5085a6e9d3480ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=794 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /tmp/ysyx-t3f-module-final-review/tb_ooo_com...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 859
- `line_count`: 9
- `sha256`: 47454a3dce09d220771f42106e19c7d47d5c42fcd9037535ac8d701e3a19267f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=859 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /tmp/ysyx-t3f-module-final-rev...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 846
- `line_count`: 9
- `sha256`: 031722eae003a924f5549d18105a8a6b56596830932f3385c99b31ec96a0fdbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=846 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /tmp/ysyx-t3f-module-final-revie...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17107
- `line_count`: 78
- `sha256`: e4e37190ec7775f8dd9ca84af0566eea36effa27b68da4f77da5a7629d9fdf7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17107 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/ysyx-t3f-module-final-review/tb_ooo_core_top_gl...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 38090c2ca0fcc6abaf16d80beefdb7031d5ca3cad5359ea1bb29ec89a7eecf14
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /tmp/ysyx-t3f-module-final-review/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 510
- `line_count`: 5
- `sha256`: ba930cb9d2a6b2095afbc257806e7f35482dce963859a8898e97ef7b97dcc119
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=510 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /tmp/ysyx-t3f-module-final-review/tb_o...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 5
- `sha256`: 6f20e9085f7df8ce726e767aecec6b16753640dcbc47ee90ddb2892eaf1af8ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=602 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /tmp/ysyx-t3f-module-final-review/tb_ooo_data_wo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: 3233c9b92fad6b352cdd62c7af8f59b7573b0663d21053041c83a556edd38224
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /tmp/ysyx-t3f-module-final...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 5
- `sha256`: c4b65d0649bc49b38f000369fc9c4efbee2ce5e6882bfca0206bb6660506de91
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=526 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /tmp/ysyx-t3f-module-final-r...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 5
- `sha256`: 256d430a1cab19084d9c98e9fcb05ff97ef8a36eb175bf1924627c9c24382eef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=526 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /tmp/ysyx-t3f-module-final-r...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8515
- `line_count`: 60
- `sha256`: 0ac98f69141b263a349360ea4168b0d0de9eeb98322dd9cef333b42f751b30e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8515 bytes; lines=60; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/ysyx-t3f-module-final-review/tb_ooo_dispa...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89747
- `line_count`: 717
- `sha256`: d85f415d54fade8a6cd154f7afa9d8daa3946461453490d2f802b62189eafcf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89747 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86490
- `line_count`: 650
- `sha256`: 31c2cb7261024b443bed5ac9e5cbb03a90d583ab83dbea399c12d57b4de2c741
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86490 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86461
- `line_count`: 650
- `sha256`: 7a14f37ecc4466f4b17eb05d0d0c10e4d32db7d6b3e94f3f4e4e8e7be18cfe8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86461 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89425
- `line_count`: 673
- `sha256`: 69c0faddf2193f19b8e543ed3e294f3bcd7ba1ef0c0451e172f80d7568419eca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89425 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: 55459cfaff8dd6e225f285cbe5e11a738c0bf7391f36858486f84e9d16b5ff85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/ysyx-t3f-module-final-review/tb_ooo_f...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 583
- `line_count`: 5
- `sha256`: 8d995a029477d4ed0b59ff481aeed9d37b738cdaeb3299f2d0d6de6611273c1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=583 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /tmp/ysyx-t3f-module-final-rev...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 637
- `line_count`: 5
- `sha256`: a574682d54fe91dbb945067e3b3821d58ec389845ff792808e1775ed0408e643
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=637 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /tmp/ysyx-t3f-module-final-review/tb_o...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 5
- `sha256`: 3bcce62bcdc3ac76f5ce46a8b2355fb8f5b998296ae3323282ec698826d2ab07
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=622 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /tmp/ysyx-t3f-module-final-review/tb_ooo_f...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 5
- `sha256`: 49fca35e07ba0b468f2e8cd25b54fc6eb8ed12c99e49b17468cdfad4341d8e85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=560 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /tmp/ysyx-t3f-module-final-review/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 4b6f86ce7b543bef501bf93caed1921cc0d0a27ad1b5b8e4f38f21006f2b34e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fet...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 501
- `line_count`: 5
- `sha256`: a18c9c8ff7647c845b941534718f61530e6a0ab5a9b20d75e9460a5fa5aa67d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=501 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /tmp/ysyx-t3f-module-final-review/tb...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 655
- `line_count`: 6
- `sha256`: d89ae2d349e001b98bd293a4b72d6fb25e7fd5d5064af57261f2bb12207efe48
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=655 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /tmp/ysyx-t3f-module-final-review/tb...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87826
- `line_count`: 664
- `sha256`: e9721b349315a4ea3154092e8c74782a03385f4d286a5d16caf7c292c5d7a48e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87826 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 556
- `line_count`: 5
- `sha256`: eb152140885925730e6134266e70cf6b27abfa3d17e014c11241b93be89d3b26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=556 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/ysyx-t3f-modu...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 915addbe7fd7be60375bb24443ffa6f2e1afa0a33bfe8c26d83df454059409e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fet...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17117
- `line_count`: 78
- `sha256`: bae32dc789ad896c76a334d4f665df374056c3abf42fba8b47590aafa8eecf86
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17117 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fetch_t...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 455
- `line_count`: 5
- `sha256`: a5f1ecdb26b7c81d9456b0860495a4e32ea362c28c03c74e14781f7a368fce69
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=455 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_arith_ga...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 246691c99e24118b0524ae18b33458687339cb63c21084aed485f5e1435e0c77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_cl...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: 68726b679cd9ba7db005723d038deac4b051a80551d19bf3d6506414374dd9eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_comp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: 9aa81c9945d1ed0f9a64197a68b7faa94d2690d1264d06e33b3babdf7efd4c1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_conv...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3289
- `line_count`: 28
- `sha256`: a9db2cc398d20b6231651bee365d6faa48517102d29a2fa5da38c5ff2355510f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3289 bytes; lines=28; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_issue_...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 04e7464b7f625cbd6814896a901a6e95818a039c68cf991e2a6a3c992faa9811
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_iter.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1434
- `line_count`: 13
- `sha256`: b283a5f8fd58556c5c20cda18630ee56dee963b47487e37c027d24ab2d252e95
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1434 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /tmp/ysyx-t3f-module-final-r...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 597
- `line_count`: 5
- `sha256`: 40e59f40108f6f9cde1147eda442b1b40eab547456eee5fb757f9464de33bb41
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=597 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_long...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 751
- `line_count`: 9
- `sha256`: 2c7206f0ff2d3b60dcc0e0a018fdec6c7c6c345cad924e9b6408f7eefc244fd2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=751 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_reg_file.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 447
- `line_count`: 5
- `sha256`: bdc08c426c2827cf6be271b5ca637b5f168e8d9398fe8deb7b1470660b4f1d8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=447 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fp_sgnj_gate....

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: d508547df5cb53c7fb6ecba110cc3737e511ad5fbcdeb3441b9f7f8403b423be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /tmp/ysyx-t3f-module-final-review/tb_ooo_free_list.vvp /home...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 497
- `line_count`: 5
- `sha256`: 42e4226ac05927dd317057f7f639a30fdb22f7c06fddfc54555bb0d798112904
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=497 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/ysyx-t3f-module-final-review/tb_o...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 905
- `line_count`: 10
- `sha256`: 8f0e4d1a2d5c2f7dfb9b13dfd55315454d9a2aa3af51b619e1304339df032feb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=905 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /tmp/ysyx-t3f-module...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 817
- `line_count`: 7
- `sha256`: 4431e755a731c656646286fcef83db15ea0bd1dcb5f6bc6779dfbd69a7c39eb8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=817 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /tmp/ysyx-t3f-module-final-review/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 0f42e0aee7ad2dd0ef004bd502a3ceca656392158e75d2d3a93110a29af19fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_fro...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 5
- `sha256`: 7873d79095cbcac35277aac2d8d8da28352f4040815d9dd7e5f57cb979208fd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=491 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /tmp/ysyx-t3f-module-final-review/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3535
- `line_count`: 32
- `sha256`: 2ba6b3679fbb56a000b39d85591ff8967ca5c5a01f3a90f9d6abb45a0ab21143
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3535 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /tmp/ysyx-t3f-module-final-review/tb...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15305
- `line_count`: 102
- `sha256`: a0facf73671f453dd38f361def3c4154cd684e5150fa8583b678d47aca0a8ad9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15305 bytes; lines=102; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/ysyx-t3f-module-final-review/tb_ooo_int_backend.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7557
- `line_count`: 58
- `sha256`: b6a23b650930c5156e96352d765d679c8daac9e49cdcb31d63ff11e7de1b7faa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7557 bytes; lines=58; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/ysyx-t3f-module-final-review/tb_ooo_int_iss...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52151
- `line_count`: 392
- `sha256`: 1b8e429b325adce804d7267b709f8894ea1a4252d911892244457ad91aa6edf9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52151 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o /tmp/ysyx-t3f-module-final-review/tb_ooo_mem_axi_b...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 949
- `line_count`: 8
- `sha256`: a46f17ea4b0dc7dff1749a27e284a97bdd9ad5a1e5669087ae1021fcdc71a964
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=949 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 447
- `line_count`: 5
- `sha256`: 202987ae5ad82ca76a901af4de0ac6313f91502728f44132525968eacabe9495
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=447 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /tmp/ysyx-t3f-module-final-review/tb_ooo_muldiv_unit.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1089
- `line_count`: 11
- `sha256`: 95657487ce6749bc0f03992a48b93bd4698b807f3bc3e9a6d678950f93b224ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1089 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /tmp/ysyx-t3f-module-final-rev...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 879
- `line_count`: 10
- `sha256`: 38e3bdf91f7272d78702fe48b3943e090c35914d4de61bc1b84d3bde174acbc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=879 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /tmp/ysyx-t3f-module-final...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 855
- `line_count`: 9
- `sha256`: 2e077e15f35ca04ceed7f5b2356bdfd78d496b44348c156082a4d4d2c73c972e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=855 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /tmp/ysyx-t3f-module-final-rev...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 724
- `line_count`: 6
- `sha256`: ad8d6e4419cc109df7d16f6924f2c9e87f7d464e89d0af9249bf9023423086cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=724 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /tmp/ysyx-t3f-module-fin...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 461
- `line_count`: 5
- `sha256`: 1636e2eee40b44a11b00a7d31d61fd7b798a68970fbf0c62cf776d3cd34b0d8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=461 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /tmp/ysyx-t3f-module-final-review/tb_ooo_phys_reg_fi...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17093
- `line_count`: 78
- `sha256`: 2ce3999d9a7a179c421eb8e29090d420925ca9978e7ad02b9c22f6d93e202ece
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17093 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/ysyx-t3f-module-final-review/tb_ooo_priv_system.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: fb9d243316e5ccaf387174f5f475d0913c054c80295b84653d44ee7d4deabb22
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /tmp/ysyx-t3f-module-final-review/tb_ooo_ras_upd...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 704f5939af6ba1ee194dfac886b884781e4366321c982acfc0083dabc729767d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/ysyx-t3f-module-final-review/tb_ooo_redir...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: 677f2460182b1a05b840b5ac89f413a0613b3a4fb55e100f4b9ae579faa237b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /tmp/ysyx-t3f-module-final-review/tb_ooo_rename_map.vvp /h...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 737
- `line_count`: 8
- `sha256`: 5c809755711a7b0c5a02b01325cfd8669926d9d6b1606062bbe90fe90756ac59
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=737 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/ysyx-t3f-module-final-review/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 837
- `line_count`: 9
- `sha256`: ac27581d80e15051813810049c93956fce023b369b293ed0244c4b2a6b48f31d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=837 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /tmp/ysyx-t3f-module-final-review/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 970
- `line_count`: 9
- `sha256`: 742eddcfccbeefe9536cdad55976c01b004929f911e15ae06b5e0275537dcd7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=970 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/ysyx-t3f-module-final-review/tb_ooo_store_queue.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155623
- `line_count`: 1113
- `sha256`: 4a234e0ba0ad0c718ceebc95bfae359c81989f3bb9025a884385e43dc94318c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155623 bytes; lines=1113; PASS=2; tail=_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in arr...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: 67af6ddd660831efc83b2f8e1fa6e2b812d40eeff47aaf1ff8b2a3f2014a4544
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /tmp/ysyx-t3f-module-final-review/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 552
- `line_count`: 5
- `sha256`: 787eb4f5cfbf9a4457215c85094c81c511357557ead3689fc3c5d2367aec7b2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=552 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /tmp/ysyx-t3f-module-final...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: c6a7d08f219733e13160efcc04b69b04e93f019c7e329ccc138c67ec505f5b49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/ysyx-t3f-module-final-review/tb_pipe_stage_reg.vvp /h...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17565
- `line_count`: 134
- `sha256`: f1e9a1bd019e2ad01a1ddb3faab1ab0a6faa061c4d41d5eb35869a5eb669a1cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17565 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /tmp/ysyx-t3f-module-final-review/tb_pmp_checker.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 376
- `line_count`: 5
- `sha256`: 5fa39d104c87efb6c45989078b1ed152d04ca7f8ba087e9664f8fa646c578476
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=376 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /tmp/ysyx-t3f-module-final-review/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 5
- `sha256`: ebe01db5055b97736c54f9a54e99eaeb56657e3dcc93b92239f6be9024d6ac38
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=374 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /tmp/ysyx-t3f-module-final-review/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review/summary.txt

- `kind`: txt
- `size_bytes`: 3122
- `line_count`: 103
- `sha256`: 10663716eb148b01ae36945183f6904239d2543eb1c595d36b33861de64b21aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 188}
- `summary`: txt evidence; size=3122 bytes; lines=103; PASS=188; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-final-review - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu -...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3254
- `line_count`: 28
- `sha256`: 21e3dcbe8bc0051b5fab27bc2d363a1dd52a6a417e9c2db1391306edbea04355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3254 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14535
- `line_count`: 89
- `sha256`: 9173ced8780e124a537e66488addc9825083ef36bff1f21ba81e1d8545152605
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14535 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14211
- `line_count`: 87
- `sha256`: 78ec75ea428ba31fb71673ed24c973c9020083c8bda4ead1d3ab6bfa7518443b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14211 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: df346793b2fd8aae5df3e18e5eede8858ab4e62ccf1ff100cf64f037647301c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17079
- `line_count`: 78
- `sha256`: 53076c2a2adafde46c83a5dfba57cb30478a11826108576cf60180628f8d81b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17079 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8487
- `line_count`: 60
- `sha256`: 636a04773b854c6d9eb71318013a6392db578d13e366690922c579fedafc0b5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8487 bytes; lines=60; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: 401de6465c8fd44cf52ee1a5e12796d5660dd17d94afb48009f92edaf0450c73
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: abefa6b3dd6db0f6ab45d37c7eca1e73ef524d13b14aaacbeac0724d3b65b472
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: 129fb938bcea093154dbc1dc8e472e099c7f6b610cd4216a77dd8561d9f30187
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89397
- `line_count`: 673
- `sha256`: 41fc91cfb82ef59366a9b847516d5d1534bdcd4ea8fbe0ed0a531b10e846c38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89397 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 6239028902f3e8ec0a26df0b9ef979adbdf27fe7f50d9be13f31bcbfd841d08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cf4de169894ef87f849d75001e9a5b21917634586e9d8bd4b305a72f7b47a4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 3998893851256d56bbb1a769e031b67cfbfb4f3ce45425ffd04465e415c22a16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17089
- `line_count`: 78
- `sha256`: 9daf05d5a40334d188fe12170953b92c3106eee513e377378bc3c0e36e26160a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17089 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3260
- `line_count`: 28
- `sha256`: edfe621b6b64150be094c0521e99d43f59d316e787b6ca02053878e01f822b76
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3260 bytes; lines=28; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15277
- `line_count`: 102
- `sha256`: 380d66b06d12e19565d60e80def738762286d77dda09cd435743e9ef48a78176
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15277 bytes; lines=102; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7529
- `line_count`: 58
- `sha256`: 3374393f25490609fbc7008f6cdb9c6122683d509705ead523947e4dd087af99
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7529 bytes; lines=58; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: dbc959eb78157c171a948166cd967c09380ae66570391575b04b76ab6957f17c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17065
- `line_count`: 78
- `sha256`: 54a2bd99e4364708c48b5d99673f1b265ab0cb5f5d1285f984d1e1f5b45a2eb8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17065 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155595
- `line_count`: 1113
- `sha256`: 6144f63bf6a1cf66d3cba5c26e47cc8cb81570d455b495f9985fd42bd3f0e8b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155595 bytes; lines=1113; PASS=2; tail=_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in arr...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests/summary.txt

- `kind`: txt
- `size_bytes`: 3144
- `line_count`: 103
- `sha256`: 4280ce0ad108595047351ac59f648bcb67d60c44dd150d44a0ad0ccd4ba36565
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 188}
- `summary`: txt evidence; size=3144 bytes; lines=103; PASS=188; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/module-tests - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_pipe_sta...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/negative/fpiq-sticky-sim.log

- `kind`: log
- `size_bytes`: 294
- `line_count`: 4
- `sha256`: 7328a222b2fd31afa8804a4e214b13295de56676263db2197069b6187552bd00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=294 bytes; lines=4; ERROR=2; tail=[FP-IQ-INT-STICKY-NEGATIVE] force entry_ready[0], issue=1 sticky=0 full=1/33 ERROR: ../vsrc/scheduling/OooFpIssueQueue.v:391: [FP-IQ-INT-STICKY-ONLY] GPR source issued before sticky ready Time: 9 Scope: tb_ooo_fp_issue_queue.dut [FP-IQ-INT-STICKY-NEGATIVE]...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/negative/fpiq-wake0-p0-sim.log

- `kind`: log
- `size_bytes`: 200
- `line_count`: 3
- `sha256`: 9ba3b72a974f1b569360495a6c06e6af58387fc5aac4693c8aa4eebc8c73ca34
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=200 bytes; lines=3; ERROR=2; tail=[FP-INT-WAKE-WRITE-NEGATIVE] arm lane0 p0 wake ERROR: npc/rv64/vsrc/scheduling/OooFpIssueQueue.v:395: [FP-INT-WAKE-WRITE] lane0 formal wake targets p0 Time: 4 Scope: tb_ooo_fp_issue_queue.dut

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/negative/fpiq-wake1-p0-sim.log

- `kind`: log
- `size_bytes`: 200
- `line_count`: 3
- `sha256`: 432257f7b67e4c238258af9c42cabc343596a00183de36bd9f167bd58e654111
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=200 bytes; lines=3; ERROR=2; tail=[FP-INT-WAKE-WRITE-NEGATIVE] arm lane1 p0 wake ERROR: npc/rv64/vsrc/scheduling/OooFpIssueQueue.v:399: [FP-INT-WAKE-WRITE] lane1 formal wake targets p0 Time: 4 Scope: tb_ooo_fp_issue_queue.dut

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/negative/prf-read8-compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/negative/prf-read8-sim.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 6
- `sha256`: 33ef153da6e3118ab24a8949ae61a4e8cdc08d032292882fec357639bcc8d6bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"ERROR": 2, "PASS": 2}
- `summary`: log evidence; size=384 bytes; lines=6; ERROR=2; PASS=2; tail=[PRF-READ8-STORED-NEGATIVE] force read8 across assertion edge ERROR: npc/rv64/vsrc/regread_bypass/OooPhysRegFile.v:110: [PRF-READ8-STORED-ONLY] read8 differs from registered state Time: 32 Scope: tb_ooo_phys_reg_file.dut [PRF-READ8-STORED-NEGATIVE] complete...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-axixbar-paths.rpt

- `kind`: rpt
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-check-setup.txt

- `kind`: txt
- `size_bytes`: 95684
- `line_count`: 4030
- `sha256`: 9dfdcc9ede24b064e1cce61a03d3754370fa163e77293fa5828f8b66b540785d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: txt evidence; size=95684 bytes; lines=4030; markers=<none>; tail=_32_ psram_axi_araddr_o_33_ psram_axi_araddr_o_34_ psram_axi_araddr_o_35_ psram_axi_araddr_o_36_ psram_axi_araddr_o_37_ psram_axi_araddr_o_38_ psram_axi_araddr_o_39_ psram_axi_araddr_o_3_ psram_axi_araddr_o_40_ psram_axi_araddr_o_41_ psram_axi_araddr_o_42_...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-custom-focus-paths.rpt

- `kind`: rpt
- `size_bytes`: 469365
- `line_count`: 4303
- `sha256`: 9396303a31f94fab9a7fecabfa5d1bb9df17f904c438464133517c6d6a035413
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=469365 bytes; lines=4303; markers=<none>; tail=_core/u_csr_file/_08710_/Y (AOI221X0P5H7L) 0.083 16.138 ^ u_core/u_csr_file/_08743_/Y (OA211X1P4H7L) 0.047 16.185 ^ u_core/u_csr_file/_08744_/Y (BUFX1P4H7L) 0.086 16.271 ^ u_core/u_csr_file/_08745_/Y (BUFX7H7L) 0.095 16.366 ^ u_core/u_csr_file/_08746_/Y (BU...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-ifu-paths.rpt

- `kind`: rpt
- `size_bytes`: 469365
- `line_count`: 4303
- `sha256`: 9396303a31f94fab9a7fecabfa5d1bb9df17f904c438464133517c6d6a035413
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=469365 bytes; lines=4303; markers=<none>; tail=_core/u_csr_file/_08710_/Y (AOI221X0P5H7L) 0.083 16.138 ^ u_core/u_csr_file/_08743_/Y (OA211X1P4H7L) 0.047 16.185 ^ u_core/u_csr_file/_08744_/Y (BUFX1P4H7L) 0.086 16.271 ^ u_core/u_csr_file/_08745_/Y (BUFX7H7L) 0.095 16.366 ^ u_core/u_csr_file/_08746_/Y (BU...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-manifest.txt

- `kind`: txt
- `size_bytes`: 1459
- `line_count`: 11
- `sha256`: bc81ee8cb0433f8002e3a0f1e60381782c3e74b5ac151e567a14bf4afc87cd5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: txt evidence; size=1459 bytes; lines=11; markers=<none>; tail=timestamp=2026-07-13T11:48:43+08:00 command=/home/lyg/tools/OpenSTA/build/sta /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current-5ns.tcl period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-netlist-focus-names.txt

- `kind`: txt
- `size_bytes`: 12275
- `line_count`: 80
- `sha256`: c6b34c08cd6353fa37ddca1fe7114e8be044e2d71afa6f07d9d870da4d476b68
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: txt evidence; size=12275 bytes; lines=80; markers=<none>; tail=756196:, csr_satp_w_55_, csr_satp_w_56_, csr_satp_w_57_, csr_satp_w_58_, csr_satp_w_59_, csr_satp_w_60_, csr_satp_w_61_, csr_satp_w_62_, csr_satp_w_63_, csr_svpbmt_en_w, ctrl_commit_valid_q, direct_branch0_dispatch_valid_w, direct_branch0_fire_w, direct_bra...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 08270955fe80f4f5d06621746e7290d280fceb4eaa09baab05cc4d58650d52fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.54e-02 1.06e-04 1.81e-04 9.56e-02 80.0% Combinational 7.13e-03 8.54e-03 4.64e-04 1.61e-02 13.5% Clock 2.80e-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-summary.txt

- `kind`: txt
- `size_bytes`: 231
- `line_count`: 10
- `sha256`: 6a84512a2a7660d5a466a8150fb706f8d6e94f5558fd3dcaf0353b36996de4cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=231 bytes; lines=10; PASS=2; tail=status=PASS period_ns=5.0 wns max -12.84 tns max -284551.97 top40_requested=40 top40_reported=40 ifu_top40_paths=22 axixbar_top40_paths=0 custom_focus_top40_paths=22 non_signoff=ideal_clock,no_spef,no_cts,no_ocv,placeholder_macros

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-current-top40.rpt

- `kind`: rpt
- `size_bytes`: 846717
- `line_count`: 7779
- `sha256`: 109eb2ee8511e8220034ea1ddc0d7ab3f41bd3d7cacb5f579588f03b4da1952c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=846717 bytes; lines=7779; markers=<none>; tail=cute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20264_/Y (OA21X0P7H7L) 0.496 14.601 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20298_/Y (NOR4X0P5H7L) 0.143 1...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-dcache-to-fp-exec.rpt

- `kind`: rpt
- `size_bytes`: 165626
- `line_count`: 1374
- `sha256`: 727309484f85f04c50eeb8bcbf2c22db2b8479d471a182c64025310606ab9425
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=165626 bytes; lines=1374; markers=<none>; tail=ck) Endpoint: u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_exec1_stage/_34_ (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_clock Path Type: max Delay Time Description --------------...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-focused-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-focused-counts.txt

- `kind`: txt
- `size_bytes`: 98
- `line_count`: 7
- `sha256`: a87957ead1852e8e6562956ab43989fd93235a9e100b5070c9d1c8b7f3fc28ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: txt evidence; size=98 bytes; lines=7; markers=<none>; tail=fp_exec_d=82 fp_iq_q=628 int_prf_q=4032 int_wake0=1 int_wake1=1 gpr_read_data=64 dcache_rdata=113

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-focused-summary.txt

- `kind`: txt
- `size_bytes`: 513
- `line_count`: 16
- `sha256`: a4b8c484bae85fcbaf89ed76fa8160589e602b59e8a11c368552358893e40e2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=513 bytes; lines=16; PASS=2; tail=status=PASS netlist_sha256=ed05a3609ff3c23109d3417506768511438bac00eb79f95d20e4fccc24f87654 fp_exec_d=82 fp_iq_q=628 int_prf_q=4032 int_wake0_source=1 int_wake1_source=1 int_wake0_fanout_endpoints=11 int_wake1_fanout_endpoints=11 int_wake0_exec_endpoints=0...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-focused.tcl

- `kind`: tcl
- `size_bytes`: 5066
- `line_count`: 129
- `sha256`: bef6f0cf584eb4b50f95c1b261d133c80bc8793a11252449fa4850c47433860e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: tcl evidence; size=5066 bytes; lines=129; markers=<none>; tail=proc require_env {name} { if {![info exists ::env($name)] || $::env($name) eq ""} { error "required environment variable is missing: $name" } return $::env($name) } proc write_note {path text} { set fp [open $path w] puts $fp $text close $fp } proc report_f...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-fpiq-q-to-fp-exec.rpt

- `kind`: rpt
- `size_bytes`: 150449
- `line_count`: 1170
- `sha256`: 6effd65bc883903f77304c093b720551f79629d81682c50084f1d7817b09ac5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=150449 bytes; lines=1170; markers=<none>; tail=^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_convert/_07592_/Y (OA211X1P4H7L) 0.088 6.385 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_convert/_075...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-gpr-read-data-to-fp-exec.rpt

- `kind`: rpt
- `size_bytes`: 16
- `line_count`: 1
- `sha256`: f5a05b71b72236dfdea1b7eefa9c4944bfc9eb457ec43e2f4c03f52f84f4050d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=16 bytes; lines=1; markers=<none>; tail=No paths found.

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-int-prf-q-to-fp-exec.rpt

- `kind`: rpt
- `size_bytes`: 85091
- `line_count`: 766
- `sha256`: ec8116238c6925befa6d47cb444c6d450361a3aedd38218f65a4fcf09dc31c00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=85091 bytes; lines=766; markers=<none>; tail=.062 3.659 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/_07253_/Y (MUX2X0P5H7L) 0.040 3.699 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/_07256_/Y (OAI211X1P...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-int-wake0-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 1342
- `line_count`: 13
- `sha256`: e12be40295a6bf8fd6ebbd9d2c270d18acc3cf199edb1612bfb783559ffad462
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: txt evidence; size=1342 bytes; lines=13; markers=<none>; tail=source_count=1 endpoint_count=11 u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_issue_queue/_5978_/E u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_issue_q...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-int-wake0-to-fp-exec.rpt

- `kind`: rpt
- `size_bytes`: 16
- `line_count`: 1
- `sha256`: f5a05b71b72236dfdea1b7eefa9c4944bfc9eb457ec43e2f4c03f52f84f4050d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=16 bytes; lines=1; markers=<none>; tail=No paths found.

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-int-wake1-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 1342
- `line_count`: 13
- `sha256`: e12be40295a6bf8fd6ebbd9d2c270d18acc3cf199edb1612bfb783559ffad462
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: txt evidence; size=1342 bytes; lines=13; markers=<none>; tail=source_count=1 endpoint_count=11 u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_issue_queue/_5978_/E u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_issue_q...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/opensta-fresh/opensta-t3f-int-wake1-to-fp-exec.rpt

- `kind`: rpt
- `size_bytes`: 16
- `line_count`: 1
- `sha256`: f5a05b71b72236dfdea1b7eefa9c4944bfc9eb457ec43e2f4c03f52f84f4050d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: rpt evidence; size=16 bytes; lines=1; markers=<none>; tail=No paths found.

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/quality/contract.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 7
- `sha256`: d776fd335315c277f4dc5d2b892cc09429bc1d1a1357b09d721d624a706afdf8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=456 bytes; lines=7; PASS=2; tail=Script started on 2026-07-13 12:03:17+08:00 [COMMAND="make -C npc/rv64 check-contract" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=81 基线=59 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ /...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/quality/lint.log

- `kind`: log
- `size_bytes`: 8694
- `line_count`: 6
- `sha256`: be77902f01ba10830f4ebf4d59a37ee988d0c38758d4fec8d087b96c3fd4e432
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=8694 bytes; lines=6; markers=<none>; tail=Script started on 2026-07-13 12:03:17+08:00 [COMMAND="make -C npc/rv64 lint" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/l...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/quality/style.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 6
- `sha256`: a6e468eb200bc7589dc7f93869760794a44d8e53a938dbf079b5379a1b78c143
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=411 bytes; lines=6; PASS=2; tail=Script started on 2026-07-13 12:03:17+08:00 [COMMAND="make -C npc/rv64 check-rtl-style" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/red/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3346
- `line_count`: 31
- `sha256`: 4592810a31e6ac69c5536236bbeb5024ebff1a3c22234bbfde127f2bb2f66273
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: log evidence; size=3346 bytes; lines=31; FAIL=8; PASS=2; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3f-int-to-fp-fast-wakeup/evidence/red/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 904
- `line_count`: 13
- `sha256`: fa095f4f232358b8685479fa66d9cea142e08e241724d80e87e1161800fe3f65
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T04:08:37+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: log evidence; size=904 bytes; lines=13; FAIL=12; PASS=2; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...
