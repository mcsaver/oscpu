# Evidence Index

## 基本信息

- `task_id`: 2026-07-26-serialize-system-trap
- `task_slug`: serialize-system-trap
- `profile`: rv64-linux
- `asset_count`: 21
- `total_size_bytes`: 671743

## 证据资产

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: f461c17d41f5758d20d940868e573a03270abbf0b70fc0d2eb3a5378bb43f9f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=130 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 155
- `line_count`: 6
- `sha256`: 17664962cd1567c20052fc78a70a50660d0c6219630a67f825e1ab8278230ddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=155 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/history/study/README.md PASS Linux/README.md

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 27144
- `line_count`: 321
- `sha256`: 8adf0e263c094d9056ecc4f7517e44727e985f2999a7b561ebd61c0a4466b93b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=27144 bytes; lines=321; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop' smoke-...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 13947
- `line_count`: 199
- `sha256`: 37ab83512032880d2970096f105f9162bcac870c7359b85a0c4e1e5c0d73789f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=13947 bytes; lines=199; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LIN...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 7948
- `line_count`: 129
- `sha256`: 77e93ced942da3fb65d99eec1a6485d3e95e7152de990042569cff4148126f9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=7948 bytes; lines=129; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [0m [1;34m[paddr.c:92 npc_init_mem] physical memory area [0x0000000080000000,...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 8559
- `line_count`: 122
- `sha256`: 79c076cae800b67762b53d58643bc140eabb68571db10c5e4c91e6c3eea1d44f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=8559 bytes; lines=122; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:92 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffff...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 13871
- `line_count`: 198
- `sha256`: b77bc0b394324f550bd3864d79983b43c79a76baddf4af445e934215fac33a76
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=13871 bytes; lines=198; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LINK='/usr/bin/clang++' VERILATOR_OPT_FAST='-O3 -march=native' VERILATOR_OPT_GL...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 338
- `line_count`: 4
- `sha256`: 98ab37a499562d3651f86ab271fd84f56e5ab5594633832219bfae189552b078
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {}
- `summary`: log evidence; size=338 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-07-26-se...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287048
- `line_count`: 2103
- `sha256`: 742818ba89c86d22cad0198b24ccd57e42233fde8e69beee67b567c923341d64
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287048 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 121570
- `line_count`: 670
- `sha256`: 9c2cd45e1067256165fb9500def5c4c00f18f8df0166963812d2675de43582e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 3, "symbolic": ["__0__", "__1__", "__2__", "__3__", "__4__", "__5__", "__6__", "__7__", "_____"]}
- `summary`: log evidence; size=121570 bytes; lines=670; PASS=3; symbolic=__0__,__1__,__2__,__3__,__4__; tail=O3 -DNPC_XLEN=64 -DNPC_GUEST_ISA_RV64=1 -I/home/lyg/PA/ysyx-workbench/npc/rv64/csrc/include -include /home/lyg/PA/ysyx-workbench/npc/rv64/include/generated/autoconf.h -include VNpcSimTop__pch.h.fast -c VNpcSimTop___024unit__0.cpp clang++: warning: precompil...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 692
- `line_count`: 17
- `sha256`: a28b67a030d16f0846658895584d3d4fb16b92878fa581b29b63b75f07754298
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=692 bytes; lines=17; PASS=6; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATIVE] cut dual-memory lane mmu_flush chain rejected [PASS] IFU ordinary-sto...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 59ef82b8d34c4d8e27ccd43f2469d2b2ef223c76815ff75606d1b6f620166254
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 5
- `sha256`: 857ba22e03ab8db828b31f0c1b80da79244207c57b4663b9ff3fea212f695a32
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=349 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 332
- `line_count`: 11
- `sha256`: ca3d5ed1dcac527d3e713735ad7c029b72e48f3f7448705ae5ccfd23716d2705
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=332 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty)...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 120324
- `line_count`: 648
- `sha256`: 548b2219679a355efcfbed4adda4c817c093592d9068c6febc95259f3b006f8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__", "__4__", "__5__", "__6__", "__7__", "_____"]}
- `summary`: log evidence; size=120324 bytes; lines=648; symbolic=__0__,__1__,__2__,__3__,__4__; tail=or/include/vltstd -DVERILATOR=1 -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -DVM_TRACE_SAIF=0 -DVM_VPI=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-int-in-bool-context -Wno-shadow -Wno-sign-compare...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 28926
- `line_count`: 153
- `sha256`: b86c8a6662f11b25374fe554d84a6d36fa0ed259a7f848bc672214797806484d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=28926 bytes; lines=153; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [0m [1;34m[paddr.c:92 npc_init_mem] physical memory area [0x0000000080000000, 0x0...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 27391
- `line_count`: 148
- `sha256`: 4dc51000b361c789496a51eb9d663925809426f965422b8cf7cbc600f4317252
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27391 bytes; lines=148; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:92 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff]...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9517
- `line_count`: 161
- `sha256`: 779301360bf4af56cbbb8083981fa16cf65f62c3a6f274f45c8ad2f9e695e516
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 310}
- `summary`: log evidence; size=9517 bytes; lines=161; PASS=310; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-26-serialize-system-trap/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T16:05:03+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
