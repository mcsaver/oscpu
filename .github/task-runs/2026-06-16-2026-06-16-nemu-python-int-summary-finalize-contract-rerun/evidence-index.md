# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun
- `task_slug`: 2026-06-16-nemu-python-int-summary-finalize-contract-rerun
- `profile`: nemu-dev-gate
- `asset_count`: 22
- `total_size_bytes`: 413748

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/check-python-int-summary-fail-finalizer.sh

- `kind`: sh
- `size_bytes`: 1420
- `line_count`: 43
- `sha256`: d456039a4393dc3ffa4c91ee9780fc7ac2be1d86ac9de3b9171f533f2323abb0
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: sh evidence; size=1420 bytes; lines=43; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd) if [ ! -f "$REPO_ROOT/.github/AGENTS.md" ] || [ ! -d "$REPO_ROOT/Linux" ]; then echo "failed to resolve repository root: $REPO_ROOT" >&2 exit 2 f...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-dev-focused-gate.log

- `kind`: log
- `size_bytes`: 237
- `line_count`: 2
- `sha256`: 145e4d6b87c660298f3d2c5c81cb4d83e09491023865ca2c712479b60b7e790f
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"SKIP": 2}
- `summary`: log evidence; size=237 bytes; lines=2; SKIP=2; tail=[nemu-ubuntu] SKIP: AGENT_E2E_NEMU_UBUNTU_GATE=1 未设置，默认不跑十几分钟 focused guest gate [nemu-ubuntu] next: 需要真实 guest 证据时运行 AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-gate

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1008
- `line_count`: 15
- `sha256`: c9a43f788d2dba4493db1cf8c32068b1cfe2ee90d68ba27f9aa85e1982e664fb
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: log evidence; size=1008 bytes; lines=15; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 99
- `sha256`: 224816dcdf698c54e09e04ba403de9ea27fc7e3148847dc59deae4ec07ae3d90
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8079
- `line_count`: 92
- `sha256`: d33f9a526e1bc57bc3fb81e37088b976014532af01ff46972b07ba98ef2858c7
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: log evidence; size=8079 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7347
- `line_count`: 68
- `sha256`: b2afde1be14088270ae3e118293b0c47265b248631c3c9f599e00eb064c2fc0a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: log evidence; size=7347 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 114489
- `line_count`: 2066
- `sha256`: 63bfa6b62add061bbf967e46708779c9bb6e7ce6f87a5918eaf981df022bca5d
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2358, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=114489 bytes; lines=2066; FAIL=7; PASS=2358; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=sh p 2223 PASS check-nemu-systemd-guest.sh UsePAM=no PASS check-nemu-systemd-guest.sh PreferredAuthentications=publickey PASS check-nemu-systemd-guest.sh KexAlgorithms=curve25519-sha256 PASS check-nemu-systemd-guest.sh HostKeyAlgorithms=ssh-ed25519 PASS che...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 246779
- `line_count`: 4318
- `sha256`: 888b327fd69d93ffbf222d31824137016595ab31079dc7af671f3de7127f2a36
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=246779 bytes; lines=4318; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swbreak-insert OK PASS swbreak-hit S05 PASS swbreak-vcont-hit S05 PASS swbreak-pc...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/console.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/driver.stderr

- `kind`: stderr
- `size_bytes`: 310
- `line_count`: 3
- `sha256`: ce54026b249b9f058af933bd892f609c697a9c313a2122d0b8f1aec3ecb535c4
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"FAIL": 2}
- `summary`: stderr evidence; size=310 bytes; lines=3; FAIL=2; tail=[nemu-python-int] FAIL: timeout waiting for serial FIFO: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/nemu.serial [nemu-python-int] ---- consol...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/driver.stdout

- `kind`: stdout
- `size_bytes`: 1598
- `line_count`: 19
- `sha256`: 10663477e851bd5181a42bcd6625554bd41f2533a22183b048f7e77334383e84
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: stdout evidence; size=1598 bytes; lines=19; markers=<none>; tail=[nemu-python-int] log dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer [nemu-python-int] serial fifo: /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/dummy/Image

- `kind`: file
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: file evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/dummy/fw_jump.bin

- `kind`: bin
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: bin evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/dummy/rootfs.dtb

- `kind`: dtb
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: dtb evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/dummy/rootfs.ext4

- `kind`: ext4
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: ext4 evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/nemu-python-int-preflight.py.b64

- `kind`: b64
- `size_bytes`: 5155
- `line_count`: 67
- `sha256`: fbaace082b665c6f749138c6f4c84c2bf6adf505c0f974c411542080d671a9ba
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: b64 evidence; size=5155 bytes; lines=67; markers=<none>; tail=IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwoiIiJORU1VIGZ1bGwtcm9vdGZzIFB5TG9uZy9pbnQgcHJl ZmxpZ2h0IHByb2JlLgoKVGhlIHNoZWxsIGdhdGVzIHJ1biB0aGlzIGluc2lkZSB0aGUgZ3Vlc3Qu ICBJdCBpbnRlbnRpb25hbGx5IHByaW50cyB0aGUgc2FtZQptYXJrZXJzIGFzIHRoZSBoaXN0b3Jp Y2FsIGlubGluZSBwcm9iZSBzby...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/python-int-preflight-summary.tsv

- `kind`: tsv
- `size_bytes`: 601
- `line_count`: 20
- `sha256`: a3e0d7de9981ca752de77b189d390ac8f06c18e34693d4faa21ec26d85a42709
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {}
- `summary`: tsv evidence; size=601 bytes; lines=20; markers=<none>; tail=key value status started max_cycles 20000000000 loops 5 stage_mode focused stage_tags focused stage_count 1 stage_prewarm 0 stage_timeout 120 poweroff 0 input_chunk_bytes 8 probe_bytes 3814 probe_sha256 f79c386895ff7e07106b23e8863f9189ee024f6c5b8c5d4344f805...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/python-int-preflight.cmd

- `kind`: cmd
- `size_bytes`: 9823
- `line_count`: 188
- `sha256`: 55bbb3e56a46a5976f27b87bbb1fd8d46686421364c4404bb6a896c2b4dd8559
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_PASS__", "__NEMU_PYTHON_INT_FOCUSED_BEGIN__", "__NEMU_PYTHON_INT_FOCUSED_RC__", "__NEMU_PYTHON_INT_POWEROFF_BEGIN__", "__NEMU_PYTHON_INT_PREFLIGHT_DONE__", "__NEMU_PYTHON_INT_PROBE_B64__", "__NEMU_PYTHON_INT_PROBE_BYTES__", "__NEMU_PYTHON_INT_PROBE_DECODE_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256_FAIL__", "__NEMU_PYTHON_INT_PROBE_SHA256__", "__NEMU_PYTHON_INT_PROBE_TOOL_MISSING__", "__NEMU_PYTHON_INT_STAGE_COUNT__", "__NEMU_PYTHON_INT_STAGE_PREWARM_BEGIN__", "__NEMU_PYTHON_INT_STAGE_PREWARM_PYTHON__", "__NEMU_PYTHON_INT_STAGE_PREWARM_RC__", "__NEMU_PYTHON_INT_STAGE_PREWARM_REGEX__", "__NEMU_PYTHON_INT_STAGE_PREWARM_SQLITE__"]}
- `summary`: cmd evidence; size=9823 bytes; lines=188; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_PASS__,__NEMU_PYTHON_INT_FOCUSED_BEGIN__; tail=NEMU_GUEST_PYTHON_INT_LOOPS=5 NEMU_GUEST_PYTHON_INT_STAGE_MODE=focused NEMU_GUEST_PYTHON_INT_STAGE_TIMEOUT=120 NEMU_GUEST_PYTHON_INT_STAGE_PREWARM=0 NEMU_GUEST_PYTHON_INT_TAGS='focused' NEMU_GUEST_POWEROFF=0 NEMU_GUEST_PROBE_SHA=f79c386895ff7e07106b23e8863f...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1096
- `line_count`: 4
- `sha256`: 1aaefddd9fea0b61c46e120f41e9ac758ea3ffc214fe59fe048e44a6c612aba1
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"PASS": 8, "SKIP": 4}
- `summary`: tsv evidence; size=1096 bytes; lines=4; SKIP=4; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/software-flow-contract.log nemu-ubuntu-stati...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 4373
- `line_count`: 104
- `sha256`: ea3649aaf5710e87bc94ac8ca542449c9dd8ff8f0a75e547b718dbd38c52345a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:50:30+00:00
- `markers`: {"PASS": 10, "SKIP": 8}
- `summary`: json evidence; size=4373 bytes; lines=104; SKIP=8; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/dispatch-l...
