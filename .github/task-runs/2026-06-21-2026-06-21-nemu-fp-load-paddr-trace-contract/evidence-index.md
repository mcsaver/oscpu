# Evidence Index

## 基本信息

- `task_id`: 2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract
- `task_slug`: 2026-06-21-nemu-fp-load-paddr-trace-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 408033

## 证据资产

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1008
- `line_count`: 15
- `sha256`: c9a43f788d2dba4493db1cf8c32068b1cfe2ee90d68ba27f9aa85e1982e664fb
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {}
- `summary`: log evidence; size=1008 bytes; lines=15; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 99
- `sha256`: 224816dcdf698c54e09e04ba403de9ea27fc7e3148847dc59deae4ec07ae3d90
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8079
- `line_count`: 92
- `sha256`: d33f9a526e1bc57bc3fb81e37088b976014532af01ff46972b07ba98ef2858c7
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {}
- `summary`: log evidence; size=8079 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7347
- `line_count`: 68
- `sha256`: b2afde1be14088270ae3e118293b0c47265b248631c3c9f599e00eb064c2fc0a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {}
- `summary`: log evidence; size=7347 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 123883
- `line_count`: 2230
- `sha256`: 9c2f576f7bdfa2d6d1c11a2f872cae3f61dc71a668ec033844564c3f129872f3
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2354, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=123883 bytes; lines=2230; FAIL=4; PASS=2354; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=check-nemu-python-int-preflight.sh NEMU_FP_LOAD_TRACE_PC_END PASS check-nemu-python-int-preflight.sh NEMU_FP_LOAD_TRACE_ADDR_START PASS check-nemu-python-int-preflight.sh NEMU_FP_LOAD_TRACE_ADDR_END PASS check-nemu-python-int-preflight.sh NEMU_VADDR_WRITE_T...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 251909
- `line_count`: 4408
- `sha256`: 25f76e84d59593bff1ee762d8d94694f9ffec0a3e620244b83faa6d030560e1e
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=251909 bytes; lines=4408; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=for_client_if_enabled] GDB stub client connected [0m [1;34m[src/monitor/gdbstub.c:616 handle_breakpoint_packet] GDB stub inserted hardware breakpoint at 0x0000000080000008 kind=4 [0m [1;34m[src/monitor/gdbstub.c:753 handle_continue] GDB stub continue reques...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 758
- `line_count`: 3
- `sha256`: 94f4c331d806b8ee92ffea60752a3582214504f802c66bdbe9c40a5fdc464c1b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=758 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PA...

### .github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3616
- `line_count`: 94
- `sha256`: 0132499cd8e16a8684f57ae236fbaabee6147b22bb6638e3daf243eb4c994d5b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T13:56:44+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3616 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-21-2026-06-21-nemu-fp-load-paddr-trace-contract/dispatch-log.md", "evidence_dir": ".gi...
