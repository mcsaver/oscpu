# Evidence Index

## 基本信息

- `task_id`: 2026-06-21-nemu-python-int-aslr-target-range-trace
- `task_slug`: 
- `profile`: 
- `asset_count`: 148
- `total_size_bytes`: 137462778306

## 证据资产

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/console.log

- `kind`: log
- `size_bytes`: 424904
- `line_count`: 2610
- `sha256`: d848c0a09ea25d63778b742e8b99b2a5f9d294484cf56c0299a8ba7080d59712
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_TYPE__"]}
- `summary`: log evidence; size=424904 bytes; lines=2610; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=EMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:runtime-after-journal:12:0 __PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__:13 __PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__:0x3ff7c98210 __PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__:0x3ff7c9822...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 2161
- `line_count`: 62
- `sha256`: ca67fec7967dad380ec38a563fbac27f96f0117c577b4c85cffbddf25fbe2a0c
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=2161 bytes; lines=62; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 24600
- `sha256`: d358ca1f1e8c23acfbe933ca7c49594c34982e52869d2b0ff40be17318669a25
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=24600; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/run.log

- `kind`: log
- `size_bytes`: 25415
- `line_count`: 370
- `sha256`: b44a2eb2aaa923ade89373e1dde5d3429681b50c5626e4c7417b7fc873181581
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__"]}
- `summary`: log evidence; size=25415 bytes; lines=370; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpcalc-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 282
- `line_count`: 4
- `sha256`: 5a4417fde452e0480223eba6e30cd818ce486c0c049abbbc0f1dac9b6d9e5f7b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=282 bytes; lines=4; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:1 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7ac04d0:0x3ff7ac04d0:0x3ff7ac04e0:0x859b44e0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:204 __NEMU_PYTHON_INT_TRACE_C...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/console.log

- `kind`: log
- `size_bytes`: 1420224
- `line_count`: 4143
- `sha256`: 21f5c1c8fd510d02a8600767fe5f08c3249269a4a02e79e4da8ce6e5d07d6e4e
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__"]}
- `summary`: log evidence; size=1420224 bytes; lines=4143; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=000000000 fa3=0x1p+0 fa4_raw=0x43c0000000000000 fa4=0x1p+61 fa5_raw=0x3ff38b1b9add04ba fa5=0x1.38b1b9add04bap+0 [0m [1;34m[src/cpu/cpu-exec.c:130 pc_gpr_trace_after_exec] pc-gpr-trace count=1934 pc=0x0000002aaab43a80 inst=0x50079863 snpc=0x0000002aaab43a84...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1774
- `line_count`: 54
- `sha256`: 578f098cfdec9f161d47297a3366a539e016017f129fbd569ed94ae627c842d2
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1774 bytes; lines=54; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 21868
- `sha256`: 4800f211077ba05e2fa5981243006401810124049aa2adf7243424c258da6c18
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=21868; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/run.log

- `kind`: log
- `size_bytes`: 24876
- `line_count`: 362
- `sha256`: 3ba022bd220ca3110462cdb2b508d183a64cab225185c2d4011cf2fe25c8d3f8
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__"]}
- `summary`: log evidence; size=24876 bytes; lines=362; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 280
- `line_count`: 4
- `sha256`: e528e138965ed450b052fe49a1a8e254d828d5c0dabfa170008215af871ab5e8
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=280 bytes; lines=4; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:1 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7ac04d0:0x3ff7ac04d0:0x3ff7ac04e0:0x857644e0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_COR...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/console.log

- `kind`: log
- `size_bytes`: 1416207
- `line_count`: 4108
- `sha256`: a2edc4cb7a659bf1f6cfd4f42f0d17b47fd0146125cda927d298dcfa89157e82
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__"]}
- `summary`: log evidence; size=1416207 bytes; lines=4108; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=0x1.c58dcd6e825cfp-4 priv=0 satp=0x800d300000083a8b [0m [1;34m[src/cpu/cpu-exec.c:130 pc_gpr_trace_after_exec] pc-gpr-trace count=1944 pc=0x0000002aaab43a5e inst=0x00002390 snpc=0x0000002aaab43a60 dnpc=0x0000002aaab43a60 priv=0 satp=0x800d300000083a8b ra=0x...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1774
- `line_count`: 54
- `sha256`: 31a79574a530004cad5ec386eddafce5360092be1adb2ef66b79a7b02aedb03e
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1774 bytes; lines=54; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 24698
- `sha256`: 87b53789eec965cf4ce1b87084f217cea1d45021226b4e5f2abab6c1fb26cc65
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=24698; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/run.log

- `kind`: log
- `size_bytes`: 39088
- `line_count`: 362
- `sha256`: f9d97e72774cea78d0b31915cc0b3313b5271c8356dd1e0a81311f60f31d64c4
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_MAX_REASONABLE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE_ERROR__"]}
- `summary`: log evidence; size=39088 bytes; lines=362; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 280
- `line_count`: 4
- `sha256`: 387ddaa5f75f1b54d7389664cd7a71930ad0e5cb817f8417e55fd90943e5c802
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=280 bytes; lines=4; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:1 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7ac04d0:0x3ff7ac04d0:0x3ff7ac04e0:0x85b5d4e0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_COR...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/console.log

- `kind`: log
- `size_bytes`: 1507083
- `line_count`: 4473
- `sha256`: d8204251b4058ebaba69d53fc0ceb0b2dcbb0a3e7140c432ff60eff9755da707
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_TYPE__"]}
- `summary`: log evidence; size=1507083 bytes; lines=4473; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=0000002aaab43a7c dnpc=0x0000002aaab43a7c priv=0 satp=0x800d90000008269e ra=0x0000002aaab441da sp=0x0000003ffffff060 t0=0x000000000000002e a0=0x0000003ff7bc3721 a1=0x0000000000000030 a3=0x0000000000000002 a5=0x0000002aaad22a6c s7=0x0000002aaaf2a15c s10=0x000...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1962
- `line_count`: 58
- `sha256`: 8328ff076cc4f93a6b693b501ef66179df8427274e3b08d70eed897c0be8c3ba
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1962 bytes; lines=58; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 26059
- `sha256`: 88b84294ce40a521b53e6e0dffa0f26742f67a872bef92e559d582d9b0f54b69
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=26059; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/run.log

- `kind`: log
- `size_bytes`: 25272
- `line_count`: 366
- `sha256`: fb6ad03abb6c444b898710a2ddc859b13ae6ad39b0fa5fb9f02e275e81dd3ac6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__"]}
- `summary`: log evidence; size=25272 bytes; lines=366; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-paddr-value-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 280
- `line_count`: 4
- `sha256`: f22913f3189cc8d9a286328b6ad1d778f0afe3ea92d9c8f456fe5951a91261a1
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=280 bytes; lines=4; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:1 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7a49d70:0x3ff7a49d70:0x3ff7a49d80:0x85143d80 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_COR...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/console.log

- `kind`: log
- `size_bytes`: 1285605
- `line_count`: 3910
- `sha256`: 3c50edbe5fda516fac0a3bf28ccb6e038931584f76fb92f737d95baec69c9124
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_TYPE__"]}
- `summary`: log evidence; size=1285605 bytes; lines=3910; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=71b ra=0x0000002aaab441da sp=0x0000003ffffff060 t0=0x000000000000002e a0=0x0000003ff7bc3721 a1=0x0000000000000030 a3=0x0000000000000002 a5=0x0000002aaad22a6c s7=0x0000002aaaf2a15c s10=0x0000003ff7a11bf8 fa2_raw=0x3fbc58dcd6e825cf fa2=0x1.c58dcd6e825cfp-4 fa...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 2160
- `line_count`: 62
- `sha256`: edf69fa0e04da10fe8117fca3316a77195659e4ef0b47500078726b590a9505e
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=2160 bytes; lines=62; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 25624
- `sha256`: 94d112f9368789387455baeb1a52caea61275b8b46d1e3876f7089f58407fb2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=25624; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/run.log

- `kind`: log
- `size_bytes`: 25601
- `line_count`: 370
- `sha256`: 56e8b36d4560874cc99d69ef65f2783fd1dd977fb07c5eac1587853092d13549
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__"]}
- `summary`: log evidence; size=25601 bytes; lines=370; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpload-vaddrpaddr-value-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: 3aa414eff8da801acc28e5894ae0d5ee7a1071a693170682a58ce62456831598
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=417 bytes; lines=5; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:2 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7ac04d0:0x3ff7ac04d0:0x3ff7ac04e0:0x857954e0 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:1:PYLONG_PROBE_LOOPS:-92233720368...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/console.log

- `kind`: log
- `size_bytes`: 1158154
- `line_count`: 3474
- `sha256`: bb89ff8fa11a5b0418003644eaec658e83877aef60cd30da2b8c7c74d1651cfd
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__"]}
- `summary`: log evidence; size=1158154 bytes; lines=3474; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=0x0000003ff7bc3721 a1=0x0000000000000030 a3=0x0000000000000002 a5=0x0000002aaad22a6c s7=0x0000002aaaf2a15c s10=0x0000003ff7a11bf8 fa2_raw=0x3fbc58dcd6e825cf fa2=0x1.c58dcd6e825cfp-4 fa3_raw=0x3ff0000000000000 fa3=0x1p+0 fa4_raw=0x43c0000000000000 fa4=0x1p+6...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1509
- `line_count`: 47
- `sha256`: 9629d6b69bfc30324d6059435189a67a3a7b2fb0e67e5c50cc8f0b60428f3d1b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1509 bytes; lines=47; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 24912
- `sha256`: f976233ba40e92f8449f7b265912d58a0d28f7ebecc0cdc5f8966a0c74959dcc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=24912; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/run.log

- `kind`: log
- `size_bytes`: 24522
- `line_count`: 355
- `sha256`: 4212ace78ab13e35cc02c11fb34b08e1be67afee5f25d157fa2a04e0b3e0fb8e
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__"]}
- `summary`: log evidence; size=24522 bytes; lines=355; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-narrow-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 415
- `line_count`: 5
- `sha256`: e08b6ae54f3fd96cfc00acf061f713402dbbf800d35277ca1d1f71dab9ec6cde
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=415 bytes; lines=5; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:2 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7a49430:0x3ff7a49430:0x3ff7a49440:0x85171440 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:1:PYLONG_PROBE_LOOPS:-92233720368...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/console.log

- `kind`: log
- `size_bytes`: 4791655
- `line_count`: 10511
- `sha256`: 64210b95372c7a1b1f38e6a4dde3af6a5769bf9f055f8b1b02b67463d5b010e0
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__"]}
- `summary`: log evidence; size=4791655 bytes; lines=10511; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR__; tail=dr_write_trace_after_write] vaddr-write-trace count=535 vaddr=0x0000003ff7ac04e0 len=8 data=0x0000000000000002 paddr=0x857e84e0 pc=0x0000002aaab4233e priv=0 satp=0x800d3000000826a2 host_fast=1 [0m [1;34m[src/memory/vaddr.c:563 vaddr_write_trace_after_write]...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1414
- `line_count`: 46
- `sha256`: d5e03dfc77244ee6f9e314dd45db338b8e677068f928394fc0b4387d2946ee5f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1414 bytes; lines=46; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 24802
- `sha256`: a51028d2044a1e2541c7db1a9c92204da7a8841cb07b5417c5444b5fc0515cea
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=24802; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/run.log

- `kind`: log
- `size_bytes`: 17305
- `line_count`: 233
- `sha256`: 89a959262c5c6b6cb62f9afab52906a40d82dd33d4e2bc665e229b7ee55d4880
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=17305 bytes; lines=233; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 145
- `line_count`: 3
- `sha256`: c7321c2cf8c377a02ec8cfcd7c745e62273711c120a04ce6198d4e6e3b312728
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=145 bytes; lines=3; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__:0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/console.log

- `kind`: log
- `size_bytes`: 4754622
- `line_count`: 10183
- `sha256`: 5d92c06b8b8d786cc5424b983f61a2a3a69ea289dfeabb3ab25c78fca6aaa04f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__"]}
- `summary`: log evidence; size=4754622 bytes; lines=10183; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=T_LENGTH__:4 __PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__:3 __NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:runtime-after-systemd-files:3:0 __PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__:4 __PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__:0x3ff7c98210 __PYTHON_INT_...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1509
- `line_count`: 47
- `sha256`: f9ac24f202dd143104acc34fbe5c11986d156340342e98bf4f047c0fd477f71a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1509 bytes; lines=47; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 24840
- `sha256`: adfdc5b3a83708c07ccb2050a3b29b20cfbaaa5dd95f5157137744ff5fee082b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=24840; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/run.log

- `kind`: log
- `size_bytes`: 24511
- `line_count`: 355
- `sha256`: 8fdc21182f1d5583e30a418aabc2e0734e45ec4142b6a18101346396374b0a9f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__"]}
- `summary`: log evidence; size=24511 bytes; lines=355; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-fpr-rerun-2/trace-correlate.log

- `kind`: log
- `size_bytes`: 280
- `line_count`: 4
- `sha256`: 799310ac53b3b18d94de6b9a1ce056c56684e3fc6c6fb3ca1ea14852172650df
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=280 bytes; lines=4; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:1 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7ac04d0:0x3ff7ac04d0:0x3ff7ac04e0:0x858e54e0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_COR...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/console.log

- `kind`: log
- `size_bytes`: 678186
- `line_count`: 2965
- `sha256`: 9b798c1f6c1bc28b9b458df71794a7f51dead08b6bd11f2a318a025bea4869d7
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_TYPE__"]}
- `summary`: log evidence; size=678186 bytes; lines=2965; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=ft0=0x0p+0 ft1_raw=0x0000000000000000 ft1=0x0p+0 ft2_raw=0x0000000000000000 ft2=0x0p+0 ft3_raw=0x4008000000000000 ft3=0x1.8p+1 ft4_raw=0x0000000000000000 ft4=0x0p+0 ft5_raw=0x0000000000000000 ft5=0x0p+0 fa0_raw=0x4024000000000000 fa0=0x1.4p+3 fa2_raw=0x3fe9...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 2161
- `line_count`: 62
- `sha256`: 0ffe3663e96b7e0afec25502b68e361203b784c90b7877ccf086bce1aa40dabf
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=2161 bytes; lines=62; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 21258
- `sha256`: 031ab1f365a05fb38efddf64ef84ffd9103f147fa3158738d43151b1e783cf9f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=21258; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/run.log

- `kind`: log
- `size_bytes`: 28444
- `line_count`: 369
- `sha256`: 9202b5da84b5d65570f8218086640272a463cff63792ff5339ffb4ceaf065989
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_ID__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__", "__PYTHON_INT_PREFLIGHT_PYLONG_INT10_CREATE_EARLY_OB_SIZE_VADDR__"]}
- `summary`: log evidence; size=28444 bytes; lines=369; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 282
- `line_count`: 4
- `sha256`: d6221ee915d45547b36d7c8a17576a448f83459d6aa665480637e1d85711f958
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=282 bytes; lines=4; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:1 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7a4abd0:0x3ff7a4abd0:0x3ff7a4abe0:0x8520fbe0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:205 __NEMU_PYTHON_INT_TRACE_C...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/console.log

- `kind`: log
- `size_bytes`: 719979
- `line_count`: 3104
- `sha256`: 5b3d7338fb312462a4d510a380b4fa938937868caa25ce94ccfcdb6d5f6e9a61
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_TYPE__", "__PYTHON_INT_PREFLIGHT_PROBE_MODE__"]}
- `summary`: log evidence; size=719979 bytes; lines=3104; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_FOCUSED_RC__; tail=40 s3=0x000000000000000a s7=0x0000002aaaf2a15c s10=0x0000002aab0665d8 ft0_raw=0x0000000000000000 ft0=0x0p+0 ft1_raw=0x0000000000000000 ft1=0x0p+0 ft2_raw=0x0000000000000000 ft2=0x0p+0 ft3_raw=0x4008000000000000 ft3=0x1.8p+1 ft4_raw=0x0000000000000000 ft4=0x...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 2066
- `line_count`: 61
- `sha256`: 03439f9169eb90df38d377d632afc4071f37b40ef61d788977030df6af9b9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=2066 bytes; lines=61; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 25766
- `sha256`: 8654a202203b02cf9efa819fb39e1290ce210d68a707a395762424ce042735b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=25766; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/run.log

- `kind`: log
- `size_bytes`: 18308
- `line_count`: 248
- `sha256`: 1341feb105c96aa4ad02c58d5cbf19c83f830be5b310b5e4d809a742a7b5ca4b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=18308 bytes; lines=248; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-libm-log-sd-fix-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 3
- `sha256`: c3912b73394da23db08611860ccac6101e1b7913fe0664a0eb469858e707ddf9
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=147 bytes; lines=3; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:204 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__:0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/console.log

- `kind`: log
- `size_bytes`: 515567
- `line_count`: 2715
- `sha256`: 0a8d5e8713a8236e5d60ad81bd0c0ceac3e89acb740f4f3c7f80b280bffd5314
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__"]}
- `summary`: log evidence; size=515567 bytes; lines=2715; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=[1;34m[src/memory/vaddr.c:563 vaddr_write_trace_after_write] vaddr-write-trace count=458 vaddr=0x0000003ff7ac04e0 len=8 data=0x0000000000000002 paddr=0x853d34e0 pc=0x0000002aaab3ccb8 priv=0 satp=0x800d300000083a8a host_fast=1 [0m [1;34m[src/memory/vaddr.c:5...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1509
- `line_count`: 47
- `sha256`: 835427161253c18beb12e561975cd539b78b66952254b62ede3a9f7d5b96ee35
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1509 bytes; lines=47; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 26712
- `sha256`: 017939178d99a1091bdeb2839456133c99d96bacb9ae3f6069711ae2dff70011
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=26712; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/run.log

- `kind`: log
- `size_bytes`: 38037
- `line_count`: 355
- `sha256`: 593b522a62a55e324278dc0434a474d7deb1ca14c8f931b82d4b1352a946628b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_MAX_REASONABLE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE_ERROR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_REPR_ERROR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_TYPE__"]}
- `summary`: log evidence; size=38037 bytes; lines=355; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-pc-rerun-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 280
- `line_count`: 4
- `sha256`: d5d056c40d8c46d0d39f8363b8d3128e6987cc401af84fe7336fd88c41a73b85
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=280 bytes; lines=4; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:1 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7ac04d0:0x3ff7ac04d0:0x3ff7ac04e0:0x85c284e0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_COR...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/console.log

- `kind`: log
- `size_bytes`: 2690991
- `line_count`: 5200
- `sha256`: 272bfffd2fbca6bb3f16a43e912f9f1b9cafd31a1e88d9fabde7acd152c08e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_REPR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_TYPE__", "__PYTHON_INT_PREFLIGHT_PROBE_MODE__"]}
- `summary`: log evidence; size=2690991 bytes; lines=5200; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_FOCUSED_RC__; tail=c] pc-gpr-trace count=2342 pc=0x0000002aaab43a5a inst=0x008c87b3 snpc=0x0000002aaab43a5e dnpc=0x0000002aaab43a5e priv=0 satp=0x800d900000083a85 ra=0x0000002aaab441da sp=0x0000003ffffff060 t0=0x000000000000002e a0=0x0000003ff7bc3721 a1=0x0000000000000030 a3=...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 2065
- `line_count`: 61
- `sha256`: d8653aa6ddfde8af56c7644d7ebb838ea91a455295622fdf362adbfc95a2e44a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=2065 bytes; lines=61; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 25712
- `sha256`: 2ee4c605cffee46e98b58441eef0366266855d85565cc818f970a3dec7040dcc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=25712; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/run.log

- `kind`: log
- `size_bytes`: 18263
- `line_count`: 248
- `sha256`: 2ac2b038657582f8541e85750126eda1b9b95fa85f53d1136572007964b993fd
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=18263 bytes; lines=248; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual-sd-fix-default-1/trace-correlate.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 3
- `sha256`: 5304458be2c751251c294c6129a2814487a796587ed1b67258633e883a0543b8
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=147 bytes; lines=3; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:209 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__:0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/console.log

- `kind`: log
- `size_bytes`: 688343
- `line_count`: 3394
- `sha256`: 49d58649897bd2986067030314dc675aa77586d48f136072c6e6da3d0feaec6a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__"]}
- `summary`: log evidence; size=688343 bytes; lines=3394; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR__; tail=rite-trace count=577 vaddr=0x0000003ff7ac04e0 len=8 data=0x0000000000000002 paddr=0x85a564e0 pc=0x0000002aaab3e54a priv=0 satp=0x800d300000081e8a host_fast=1 [0m [1;34m[src/memory/vaddr.c:563 vaddr_write_trace_after_write] vaddr-write-trace count=578 vaddr=...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1414
- `line_count`: 46
- `sha256`: 12652697cea47ceafbab2f50e7b97b0df90e676490c3338d74c60740815bd734
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1414 bytes; lines=46; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 21357
- `sha256`: 67a7cc4f06d1bc46cc62cc7c6c1e1e5f78199ce818283e386b2d9920a77e3a62
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=21357; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/run.log

- `kind`: log
- `size_bytes`: 17140
- `line_count`: 233
- `sha256`: 9edcb3c88c5724db3cbeebaf4b81ab5c0e370e5836bebceef61efe3467045e00
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=17140 bytes; lines=233; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-dual/trace-correlate.log

- `kind`: log
- `size_bytes`: 145
- `line_count`: 3
- `sha256`: c7321c2cf8c377a02ec8cfcd7c745e62273711c120a04ce6198d4e6e3b312728
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=145 bytes; lines=3; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__:0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/console.log

- `kind`: log
- `size_bytes`: 278394
- `line_count`: 2362
- `sha256`: f2fc7f3aca0001f31f2b67e623e440dbbe3ff8cf3c201de1beee7b4dfbd757ba
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__"]}
- `summary`: log evidence; size=278394 bytes; lines=2362; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR__; tail=508 vaddr_write_trace_after_write] vaddr-write-trace count=573 vaddr=0x0000003ff7ac04e0 len=8 data=0x0000000000000001 paddr=0x85c7d4e0 pc=0x0000002aaab3cd42 priv=0 satp=0x800d3000000839cf host_fast=1 [0m [1;34m[src/memory/vaddr.c:508 vaddr_write_trace_after...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1160
- `line_count`: 39
- `sha256`: 7a77327ff71a2b5a20ac540efa8212f243c68d51708822d0fe348262f2032421
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1160 bytes; lines=39; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 25850
- `sha256`: 796926e898a8392f8529b31d7044f654a5a251e980781a5640557b69c6c22d56
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=25850; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/run.log

- `kind`: log
- `size_bytes`: 16797
- `line_count`: 226
- `sha256`: ea762ddc31d594790f1687b75782c277ea47b6f9d305a605bf9eca6a96d94baa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=16797 bytes; lines=226; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range-failaddr/trace-correlate.log

- `kind`: log
- `size_bytes`: 145
- `line_count`: 3
- `sha256`: c7321c2cf8c377a02ec8cfcd7c745e62273711c120a04ce6198d4e6e3b312728
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=145 bytes; lines=3; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__:0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/console.log

- `kind`: log
- `size_bytes`: 72432
- `line_count`: 1103
- `sha256`: d173a7368c46998813cc0f8c512e8d2ec26733732d999dbf46a0e99f9e54d300
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__"]}
- `summary`: log evidence; size=72432 bytes; lines=1103; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=ble entries: 8192 (order: 7, 524288 bytes, linear) [ 0.300226] TCP: Hash tables configured (established 8192 bind 8192) [ 0.302377] UDP hash table entries: 512 (order: 3, 49152 bytes, linear) [ 0.304141] UDP-Lite hash table entries: 512 (order: 3, 49152 byt...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1255
- `line_count`: 40
- `sha256`: b34ef4d1899ba0b6089633b23e0af52118fd7d1798dd1bbcfd0c64a5d6fec94d
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1255 bytes; lines=40; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 23862
- `sha256`: 8fe8c8704c2aae9f990c93edc1abe5c04cb6735ac4a3b085fd0d08513bd2f52a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=23862; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/run.log

- `kind`: log
- `size_bytes`: 24971
- `line_count`: 348
- `sha256`: 312c7b4150d560c5c473051cb8085146fec1b3683aedb8258db7254b39899ead
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_MAX_REASONABLE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE_ERROR__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PREPARSE_ID_MATCH__"]}
- `summary`: log evidence; size=24971 bytes; lines=348; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create-target-range/trace-correlate.log

- `kind`: log
- `size_bytes`: 550
- `line_count`: 6
- `sha256`: 1c4298f6f254f531a5d7ba5375eb816a63e022278a1bd8b8a4a469942e38378a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=550 bytes; lines=6; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:3 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:0:PYLONG_PROBE_LOOPS:-9223372036854775807:0x3ff7ac04d0:0x3ff7ac04d0:0x3ff7ac04e0:0x857894e0 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:1:PYLONG_PROBE_LOOPS:-92233720368...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/console.log

- `kind`: log
- `size_bytes`: 102073
- `line_count`: 1590
- `sha256`: 352d848700e4d53e9c05167582b5454405df5dfb438364f9380ca80bbac23a2f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PROBE_RC__", "__NEMU_PYTHON_INT_STAGE_RC__", "__PYTHON_INT_PREFLIGHT_ARGS_TAG__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_ITER__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__", "__PYTHON_INT_PREFLIGHT_INT10_CREATE__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_PROBE_LOOPS_PLUS_ONE__"]}
- `summary`: log evidence; size=102073 bytes; lines=1590; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR__; tail=LONG_INT10_CREATE_EARLY_OB_SIZE_PADDR__:0x84be2220 __PYTHON_INT_PREFLIGHT_INT10_CREATE__:10 __PYTHON_INT_PREFLIGHT_INT10_CREATE_BIT_LENGTH__:4 __PYTHON_INT_PREFLIGHT_INT10_CREATE_OK__:12 __NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__:before-runtime:12:0 __PYTH...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 24961
- `line_count`: 325
- `sha256`: 3aada5ab971cc48c7afb53b258e9d6dc5ccb5549ce6e0af13ed9b0526bcc90f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: b64 evidence; size=24961 bytes; lines=325; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 1136
- `line_count`: 39
- `sha256`: 15032b8e1c5a606457a529dbe9bf43694e910bd2370ebc21dbdb939c42c838b0
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: tsv evidence; size=1136 bytes; lines=39; symbolic=__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=key value status started max_cycles 320000000000 loops 20 stage_mode full-lite probe_mode int10-create stage_tags before-runtime,runtime-after-core-tools,runtime-after-identity,runtime-after-systemd-files,runtime-after-journal,after-runtime stage_count 6 st...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 31132
- `line_count`: 479
- `sha256`: 8b249cf2ebebf712e2e432e2faecc9e7fb416c2580c599f2a6a29c11d46e435a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__", "__NEMU_PYTHON_INT_DISABLE_ASLR__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_FAILED_PROBE_CONTINUE__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__"]}
- `summary`: cmd evidence; size=31132 bytes; lines=479; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_DISABLE_ASLR_FAIL__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=20 NEMU_GUEST_PYTHON_INT_STAGE_MODE=full-lite NEMU_GUEST_PYTHON_INT_PROBE_MODE=int10-create NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='before-runtime runtime-after-co...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 26376
- `sha256`: 64ca4cd8b82cb7c5d0de8e91e6c56ea4af23b23583c7ac95115a965e1607aec4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=26376; markers=<none>; tail=

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/run.log

- `kind`: log
- `size_bytes`: 16531
- `line_count`: 226
- `sha256`: be124fe84efb0bbefad42b670ca7c6c634db09cd5c1e41a6dd0e15de7495c31d
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"PASS": 18, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__"]}
- `summary`: log evidence; size=16531 bytes; lines=226; PASS=18; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_PYTHON_INT_PREFLIGHT_DONE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/run.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/evidence/aslr-off-full-lite-int10-create/trace-correlate.log

- `kind`: log
- `size_bytes`: 145
- `line_count`: 3
- `sha256`: c7321c2cf8c377a02ec8cfcd7c745e62273711c120a04ce6198d4e6e3b312728
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {"symbolic": ["__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__", "__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__"]}
- `summary`: log evidence; size=145 bytes; lines=3; symbolic=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__,__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__; tail=__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:0 __NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__:0

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/run-aslr-calibrate.sh

- `kind`: sh
- `size_bytes`: 1168
- `line_count`: 33
- `sha256`: 06333c5aec7881d8d63ad9783b0d111d0e119f837172585323c8d27d5fb12571
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: sh evidence; size=1168 bytes; lines=33; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace" EVIDENCE_DIR="$RUN_DIR/evidence/aslr-off-full-lite-int10-c...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/run-target-range-trace-dual.sh

- `kind`: sh
- `size_bytes`: 2658
- `line_count`: 62
- `sha256`: 5d9860823d09d76623037e2d7056d8c01e6507067c9c878e9de337bc529449aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: sh evidence; size=2658 bytes; lines=62; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace" RUN_SUFFIX=${NEMU_TRACE_RUN_SUFFIX:-$(date +%Y%m%d-%H%M%S)...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/run-target-range-trace-failaddr.sh

- `kind`: sh
- `size_bytes`: 1374
- `line_count`: 38
- `sha256`: df5a13065c9eaf952c16de828e48893537a03f3f925b4eb31f5c714d730db7c5
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: sh evidence; size=1374 bytes; lines=38; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace" EVIDENCE_DIR="$RUN_DIR/evidence/aslr-off-full-lite-int10-c...

### .github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace/run-target-range-trace.sh

- `kind`: sh
- `size_bytes`: 1365
- `line_count`: 38
- `sha256`: 6adc78ad27174f752abb30155082f63124b057563fe26045e8ee1651c9fc0087
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T15:00:32+00:00
- `markers`: {}
- `summary`: sh evidence; size=1365 bytes; lines=38; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) RUN_DIR="$REPO_ROOT/.github/task-runs/2026-06-21-nemu-python-int-aslr-target-range-trace" EVIDENCE_DIR="$RUN_DIR/evidence/aslr-off-full-lite-int10-c...
