# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun
- `task_slug`: 
- `profile`: 
- `asset_count`: 9
- `total_size_bytes`: 8590119138

## 证据资产

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/console.log

- `kind`: log
- `size_bytes`: 117347
- `line_count`: 1759
- `sha256`: e02dd01dde1710a3a82175ea09b34161beea3a5bc7350789ef943b815f55d6cf
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_TYPE__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES__"]}
- `summary`: log evidence; size=117347 bytes; lines=1759; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_FOCUSED_BEGIN__; tail=l.c:264 serial_trace_marker_process_line] serial paddr trace marker armed paddr_start=0x0000000084c1a220 paddr_end=0x0000000084c1a227 [0m [1;34m[src/memory/vaddr.c:104 vaddr_write_trace_disarm] vaddr-write-trace disarmed reason=serial-end-marker count=0 [0m...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 21034
- `line_count`: 274
- `sha256`: 81a1c43abbe7bfe89dcc1b3bc4400fd80e8573e4c3a0fa3b522dc959dd993cee
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {}
- `summary`: b64 evidence; size=21034 bytes; lines=274; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1078
- `line_count`: 37
- `sha256`: 2361f3c727c2c865aa804d70c5d3be393237b76add03416323cfab0e6fd54011
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1078 bytes; lines=37; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 10 stage_mode full-lite stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 stage_prewarm 0 stage_time...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 27106
- `line_count`: 426
- `sha256`: 378aa43eccde0daa6eb7649e352687f02d0af873a71e3310134df5e598039052
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=27106 bytes; lines=426; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=10 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-core-tools runtime-after-identity runtime-after-...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 31540
- `sha256`: 13e1a30b84f32efa7f065ccc64d65bd7a660301e23b42c84ccd4ae95cba89c64
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=31540; markers=<none>; tail=

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/run.log

- `kind`: log
- `size_bytes`: 16774
- `line_count`: 222
- `sha256`: 98c685536a5e7d4e3fd9a84d1c8528b5b0ecd1f049b1a1762875bbe1c52d2e7c
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=16774 bytes; lines=222; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-value-byte-trace-rerun/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun/run-heavy.sh

- `kind`: sh
- `size_bytes`: 1205
- `line_count`: 34
- `sha256`: 8b53f0a48cfad22cb18c8244efd5f0ceed79ba5774784e4d9eac60623b575aec
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T13:28:41+00:00
- `markers`: {}
- `summary`: sh evidence; size=1205 bytes; lines=34; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-16-nemu-python-int-pylong-value-byte-trace-rerun" EVIDENCE_DIR="$RUN_DIR/evidence/nemu-python-int-full...
