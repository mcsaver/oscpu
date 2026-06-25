# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun
- `task_slug`: 
- `profile`: nemu-dev / manual heavy focused reproducer
- `asset_count`: 9
- `total_size_bytes`: 8590088150

## 证据资产

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/console.log

- `kind`: log
- `size_bytes`: 87542
- `line_count`: 1449
- `sha256`: 37b40367c7dae1993eb33056e41e90ff6b3c3ef06dd83434648f0643de60667a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__", "__NEMU_PYTHON_INT_STAGE_PREWARM_RC__", "__NEMU_PYTHON_INT_STAGE_PREWARM_REGEX__", "__NEMU_PYTHON_INT_STAGE_PREWARM_SQLITE__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_REPR__"]}
- `summary`: log evidence; size=87542 bytes; lines=1449; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=_INT_PREFLIGHT_PYLONG_CONST_ONE_TYPE__:int __PYTHON_INT_PREFLIGHT_PYLONG_CONST_ONE_ID__:0x3f806a40f0 __PYTHON_INT_PREFLIGHT_PYLONG_CONST_ONE_SIZEOF__:28 __PYTHON_INT_PREFLIGHT_PYLONG_CONST_ONE_REPR__:1 __PYTHON_INT_PREFLIGHT_PYLONG_CONST_ONE_BIT_LENGTH__:1...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 17873
- `line_count`: 233
- `sha256`: 36c550a4416fe5ecba69ef25c23e63d3cadb1780809d7a19fc8cf8c952e41e1b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {}
- `summary`: b64 evidence; size=17873 bytes; lines=233; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 861
- `line_count`: 28
- `sha256`: 9a85eb8f468d0dbcf77be0d15eb7bdf0c5d3d82b855a0e58fc610d31fc068f10
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=861 bytes; lines=28; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 10 stage_mode full-lite stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 stage_prewarm 1 stage_time...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 22664
- `line_count`: 354
- `sha256`: 5754b177758eb89c37c830031466706eebe69c7fb66579c68c982b12a1495906
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__", "__NEMU_PYTHON_INT_STAGE_PREWARM_RC__", "__NEMU_PYTHON_INT_STAGE_PREWARM_REGEX__", "__NEMU_PYTHON_INT_STAGE_PREWARM_SQLITE__"]}
- `summary`: cmd evidence; size=22664 bytes; lines=354; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_FOCUSED_BEGIN__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=10 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=1 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-core-tools runtime-after-identity runtime-after-...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 37006
- `sha256`: 19b5b1b0246887ce99efaa59432c374e84f349a2266a914cef9eef6c9509d9d2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=37006; markers=<none>; tail=

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/run.log

- `kind`: log
- `size_bytes`: 23692
- `line_count`: 334
- `sha256`: 77d14b6f1b7eb23b1ebc5bcfe497a0b2d4c11feedc5ff33418f328b9a410b647
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP__", "__PYTHON_INT_PREFLIGHT_ITER_OK__"]}
- `summary`: log evidence; size=23692 bytes; lines=334; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-error-state-rerun/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun/run-heavy.sh

- `kind`: sh
- `size_bytes`: 924
- `line_count`: 26
- `sha256`: aed9825ae5624b2717ace7f27a01e52ad8ce0194733a3091f50ea56511901ae0
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:18:03+00:00
- `markers`: {}
- `summary`: sh evidence; size=924 bytes; lines=26; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-error-state-rerun" EVIDENCE_DIR="$RUN_DIR...
