# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun
- `task_slug`: 
- `profile`: nemu-dev / manual heavy focused reproducer
- `asset_count`: 9
- `total_size_bytes`: 8590093945

## 证据资产

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/console.log

- `kind`: log
- `size_bytes`: 100097
- `line_count`: 1660
- `sha256`: 580e528cc390d51b6b90f6bb8fa3aed7a0f8af553abc1e3bc9175c8267f9c089
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__", "__NEMU_PYTHON_INT_STAGE_PREWARM_RC__", "__NEMU_PYTHON_INT_STAGE_PREWARM_REGEX__", "__NEMU_PYTHON_INT_STAGE_PREWARM_SQLITE__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_ARGS_LOOPS_TYPE__"]}
- `summary`: log evidence; size=100097 bytes; lines=1660; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_FOCUSED_BEGIN__; tail=SSIZE_T_SIZE__:8 __PYTHON_INT_PREFLIGHT_PYLONG_LAYOUT_VOID_P_SIZE__:8 __PYTHON_INT_PREFLIGHT_PYLONG_LAYOUT_DIGIT_CTYPE__:c_uint __PYTHON_INT_PREFLIGHT_PYLONG_CONST_ZERO_TYPE__:int __PYTHON_INT_PREFLIGHT_PYLONG_CONST_ZERO_ID__:0x3f859880d0 __PYTHON_INT_PREFL...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 17873
- `line_count`: 233
- `sha256`: 36c550a4416fe5ecba69ef25c23e63d3cadb1780809d7a19fc8cf8c952e41e1b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {}
- `summary`: b64 evidence; size=17873 bytes; lines=233; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 771
- `line_count`: 27
- `sha256`: 40df65b9cd61ed8a8e25d94913de6679f9a94b5dbf9a20fe540187831c3b7535
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=771 bytes; lines=27; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 10 stage_mode full-lite stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 stage_prewarm 1 stage_time...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 23056
- `line_count`: 365
- `sha256`: fd2c28fc74166d16d180c8cc70db7109e76b49f59e16b2e59e807b9d4e8f8855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__", "__NEMU_PYTHON_INT_STAGE_PREWARM_RC__", "__NEMU_PYTHON_INT_STAGE_PREWARM_REGEX__"]}
- `summary`: cmd evidence; size=23056 bytes; lines=365; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_FOCUSED_BEGIN__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=10 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=1 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-core-tools runtime-after-identity runtime-after-...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 38241
- `sha256`: f1490db36a9010d6886a4112e6a334ccd6087bc206d9081317d2ed0c62303e36
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=38241; markers=<none>; tail=

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/run.log

- `kind`: log
- `size_bytes`: 16624
- `line_count`: 212
- `sha256`: 6d7e0bbb7928802e862001af99219be0ce3d46d84f90291642934e88428a9463
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=16624 bytes; lines=212; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/evidence/nemu-python-int-full-lite-wide-ifetch-off-probe-continue-rerun/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun/run-heavy.sh

- `kind`: sh
- `size_bytes`: 930
- `line_count`: 26
- `sha256`: b3802fd0fd5c1a203c1202a698c3011da674bb7ea6d437df18193dba1e40440a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T09:35:42+00:00
- `markers`: {}
- `summary`: sh evidence; size=930 bytes; lines=26; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-16-nemu-python-int-pylong-sentinel-full-lite-wide-ifetch-off-probe-continue-rerun" EVIDENCE_DIR="$RUN_...
