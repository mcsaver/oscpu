# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke
- `task_slug`: 2026-06-15-nemu-ubuntu-host-perf-fallback-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 22
- `total_size_bytes`: 8592027018

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/console.log

- `kind`: log
- `size_bytes`: 16767
- `line_count`: 172
- `sha256`: 0a91936f185d2b99c631cc5642bcde8ec000cc76174bd8d1b66350d0b3e8c378
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=16767 bytes; lines=172; markers=<none>; tail=[1;34m[src/utils/log.c:30 init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/nemu.log [0m [1;34m[src/monitor/monitor.c:449 init_monitor] Block image requ...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/host-profiler.txt

- `kind`: txt
- `size_bytes`: 1798
- `line_count`: 39
- `sha256`: 13c1f12bf6f656002ae40c955c239899c5d32fc2c3425c28bd359138dd82bc82
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"WARN": 2}
- `summary`: txt evidence; size=1798 bytes; lines=39; WARN=2; tail=perf.record.requested=1 perf.record.freq=99 perf.source=system perf.path=/usr/bin/perf perf.status=unavailable WARNING: perf not found for kernel 6.6.87.2-microsoft You may need to install the following packages for this specific kernel: linux-tools-6.6.87....

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/perf-report.err

- `kind`: err
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: err evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/perf-report.txt

- `kind`: txt
- `size_bytes`: 23401
- `line_count`: 711
- `sha256`: c6e2d30e7556cd93b1a3f8b098a73345795b591c822a8538b83a4eb4d917741a
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"symbolic": ["__GI___", "__GI_____"]}
- `summary`: txt evidence; size=23401 bytes; lines=711; symbolic=__GI___,__GI_____; tail=# To display the perf.data header info, please use --header/--header-only options. # # # Total Lost Samples: 0 # # Samples: 35 of event 'task-clock:upppH' # Event count (approx.): 353535350 # # Overhead Command Shared Object Symbol IPC [IPC Coverage] # .......

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/perf-smoke.out

- `kind`: out
- `size_bytes`: 243
- `line_count`: 11
- `sha256`: 01bc269dca71c5e9bf1e5c8c5becb8de9e5c72cf91b9de557b534694e6bad5b8
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: out evidence; size=243 bytes; lines=11; markers=<none>; tail=Performance counter stats for 'true': 0.39 msec task-clock:u # 0.201 CPUs utilized 0.001937541 seconds time elapsed 0.001104000 seconds user 0.000000000 seconds sys

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/perf.data

- `kind`: data
- `size_bytes`: 1601220
- `line_count`: 11468
- `sha256`: ee0d1ed0f64712831453bd12a458a752525ac3423e8026150226c9a5202749b6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: data evidence; size=1601220 bytes; lines=11468; markers=<none>; tail=.so.2.0.7 "�" "�" ~�<�p� � "�" "�" � �V~ � P 0 { � �� /usr/lib/x86_64-linux-gnu/libreadline.so.8.2 "�" "�" � =�p� � "�" "�" ���V~ � � 0 Pu ��� /usr/lib/x86_64-linux-gnu/libmpfr.so.6.2.1 "�" "�" �}=�p� � "�" "�" ��V~ 0 � 0 �u �; � /usr/lib/x86_64-linux-gnu/l...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/profile-command.txt

- `kind`: txt
- `size_bytes`: 341
- `line_count`: 12
- `sha256`: 8685ec0125e035a52cbf706e5378981fabd144f96c52b163ec598b998f56a29f
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: txt evidence; size=341 bytes; lines=12; markers=<none>; tail=repo_root=/home/lyg/PA/ysyx-workbench rootfs_flavor=full rootfs_image=/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4 max_cycles=2000000 progress=50000000 tb_max_inst=32 opcode_mix=0 stop_detail=0 host_p...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/profile-run.log

- `kind`: log
- `size_bytes`: 31092
- `line_count`: 346
- `sha256`: 89adf1dad40cb58e7de97e1c464d954ffeb7b1f9e28338fc0031c81510c392b7
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=31092 bytes; lines=346; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/profile-summary.txt

- `kind`: txt
- `size_bytes`: 7370
- `line_count`: 211
- `sha256`: bb76abee5c5126c51397a9cfd0467dba00343ee0ac735bb7df024d1785c77949
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: txt evidence; size=7370 bytes; lines=211; markers=<none>; tail=# NEMU Ubuntu Profile Summary profile.available=1 profile.cpu.basic_block_avg_inst_x100=3198 profile.cpu.basic_block_inst=2000000 profile.cpu.basic_blocks=62524 profile.cpu.exec_us=68459 profile.cpu.exec_windows=1 profile.cpu.opcode.amo=0 profile.cpu.opcode...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-profile/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 1
- `sha256`: ebfb4ef19ae410f190327b5ebd312711263bc7579970e87d9c1e2d84e06b3c25
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=1; markers=<none>; tail=

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 752
- `line_count`: 9
- `sha256`: 8436d91cae7f3d3c287e8dfb8ecbd85054b584e5b13dcedb3552f12922dd368d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=752 bytes; lines=9; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8128
- `line_count`: 99
- `sha256`: 26fe3a0f0a1445462004accda7c989e401eb46cccfb413fb59b1def61aa13596
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=8128 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7821
- `line_count`: 92
- `sha256`: 36d130fd2672d30968223df443abecc33f6ff2d9bce6366776c3af415f2b0b60
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=7821 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7089
- `line_count`: 68
- `sha256`: e1a1b27e1975d6bcc3e2032ba6a2988ef49443ecf78afbb66dc832c43dbaf35b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {}
- `summary`: log evidence; size=7089 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-ubuntu-profile.log

- `kind`: log
- `size_bytes`: 31455
- `line_count`: 349
- `sha256`: 148b353ae41f7012f1bfd35bc458a5217e9a8169a3e7c0330b8af2cf902f3cc6
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=31455 bytes; lines=349; PASS=2; tail=[nemu-ubuntu] heavy performance profile gate make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 103484
- `line_count`: 1905
- `sha256`: 30089d88ba6aff1fe688763bbc51be0fe409762af915a6f3f24867296b094dc6
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2329, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=103484 bytes; lines=1905; FAIL=7; PASS=2329; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_SAMPLE__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_PS_BEGIN__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGR...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 243235
- `line_count`: 4252
- `sha256`: b149f6d9055d24b1fd1f4c2b08dd4aa7c63b032825b7ea18effc8db16d03f3b4
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=243235 bytes; lines=4252; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail==/home/lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-gdbstub-smoke-nemu.log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swb...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1013
- `line_count`: 4
- `sha256`: f3594eb43aad3d9ba447acfce2378992d2e6ffb892c27e4d43af9b664d7c34c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=1013 bytes; lines=4; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/run-manifest.json

- `kind`: json
- `size_bytes`: 4170
- `line_count`: 108
- `sha256`: 90c0ec156c01f69d3fdbfa8eeb9b87f77375bcbb4488499498a8f43098bc4f98
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:12:05+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=4170 bytes; lines=108; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-host-perf-fallback-smoke/dispatch-log.md", "evidence_dir"...
