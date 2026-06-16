# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile
- `task_slug`: 2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile
- `profile`: nemu-ubuntu-profile
- `asset_count`: 22
- `total_size_bytes`: 8592209084

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/console.log

- `kind`: log
- `size_bytes`: 32846
- `line_count`: 416
- `sha256`: b8b43147e637ac94c1559d9c51463b920a21cd9665a44c9d1d91e484a72cf6aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32846 bytes; lines=416; symbolic=_____; tail=OpenSBI v1.8 ____ _____ ____ _____ / __ \ / ____| _ \_ _| | | | |_ __ ___ _ __ | (___ | |_) || | | | | | '_ \ / _ \ '_ \ \___ \| _ < | | | |__| | |_) | __/ | | |____) | |_) || |_ \____/| .__/ \___|_| |_|_____/|____/_____| | | |_| Platform Name : YSYX NPC RV...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/host-profiler.txt

- `kind`: txt
- `size_bytes`: 1558
- `line_count`: 36
- `sha256`: 3046e1245cd9f0bc85e26dc70410b557bc4aecafc1c35de8acbf944bd8237bdd
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"WARN": 2}
- `summary`: txt evidence; size=1558 bytes; lines=36; WARN=2; tail=perf.record.requested=1 perf.record.freq=99 perf.source=system perf.path=/usr/bin/perf perf.status=unavailable WARNING: perf not found for kernel 6.6.87.2-microsoft You may need to install the following packages for this specific kernel: linux-tools-6.6.87....

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/perf-report.err

- `kind`: err
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: err evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/perf-report.txt

- `kind`: txt
- `size_bytes`: 8094
- `line_count`: 138
- `sha256`: 2df73f412e3a05173ac93d66102dbe8e1093ffe9e60d8ec9aae0216af93cd3fe
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"symbolic": ["__GI___"]}
- `summary`: txt evidence; size=8094 bytes; lines=138; symbolic=__GI___; tail=# To display the perf.data header info, please use --header/--header-only options. # # # Total Lost Samples: 0 # # Samples: 2K of event 'task-clock:upppH' # Event count (approx.): 21181817970 # # Overhead Command Shared Object Symbol IPC [IPC Coverage] # .....

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/perf-smoke.out

- `kind`: out
- `size_bytes`: 243
- `line_count`: 11
- `sha256`: d2e11fa965e22606bfb00ed739221f5cc4dd242e24a3d2035d845483427214fe
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: out evidence; size=243 bytes; lines=11; markers=<none>; tail=Performance counter stats for 'true': 0.34 msec task-clock:u # 0.418 CPUs utilized 0.000802406 seconds time elapsed 0.000914000 seconds user 0.000000000 seconds sys

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/perf.data

- `kind`: data
- `size_bytes`: 1741532
- `line_count`: 11706
- `sha256`: 3a3b9b5f6be167363807634ab27fe499ea1c4194023dbde80b6a18f3b74815f0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: data evidence; size=1741532 bytes; lines=11706; markers=<none>; tail=0 �� X�;� /usr/bin/gawk �� �� c� �d � �� �� �F[� � 0 4r ���q /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 �� �� � �d ` �� �� �2'� [vdso] �� �� $ �d � �� �� @D[� 0 �o R�S /usr/lib/x86_64-linux-gnu/libsigsegv.so.2.0.7 �� �� �� �d � �� �� 0@[� � P 0 { � �� /...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/profile-command.txt

- `kind`: txt
- `size_bytes`: 481
- `line_count`: 18
- `sha256`: 9eb77a5db514ae215b0f1c078b1c609c29686e04cc8bdda934fc294205f82685
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=481 bytes; lines=18; markers=<none>; tail=repo_root=/home/lyg/PA/ysyx-workbench rootfs_flavor=full rootfs_image=/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4 max_cycles=1000000000 progress=50000000 tb_max_inst=32 opcode_mix=0 stop_detail=0 hos...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/profile-run.log

- `kind`: log
- `size_bytes`: 47379
- `line_count`: 591
- `sha256`: f2cca22e754251634be038041be6c1d799568e23e73ad18289ba0a9b26d78220
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=47379 bytes; lines=591; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/profile-summary.txt

- `kind`: txt
- `size_bytes`: 7698
- `line_count`: 212
- `sha256`: af27e72b96fbba7d5850350898f12810f978e451909539b64a5a71dfe3cdec1d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=7698 bytes; lines=212; markers=<none>; tail=# NEMU Ubuntu Profile Summary profile.available=1 profile.clint.host_time_reads=1981545 profile.cpu.basic_block_avg_inst_x100=2899 profile.cpu.basic_block_inst=1000000000 profile.cpu.basic_blocks=34487049 profile.cpu.exec_us=23021446 profile.cpu.exec_window...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-profile/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 2745
- `sha256`: 97e0cb46b2a126201363b6db3d7a702f30dd3026b2035c53c4f90465bc467fe0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=2745; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 836
- `line_count`: 11
- `sha256`: 9396f30f2304f5055e5dd517873128217e28f117cf15bb6cd7592958571bd37a
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: log evidence; size=836 bytes; lines=11; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8304
- `line_count`: 99
- `sha256`: a9ffcb3618cc8797db14514404c0dfa65094ccb4584c47a0808044ff27548c30
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: log evidence; size=8304 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7997
- `line_count`: 92
- `sha256`: 4c6fe4e3d54b61a0289a6302ae13ca4403dce4062b8b604c1ee1550cf7178b25
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: log evidence; size=7997 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7265
- `line_count`: 68
- `sha256`: 0bc3f8ef6b545a96ad51b2dcb6e50d200a02ddb089cb3b1f47fdca17521fb1cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {}
- `summary`: log evidence; size=7265 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-ubuntu-profile.log

- `kind`: log
- `size_bytes`: 47766
- `line_count`: 594
- `sha256`: 9b6bb0093223bd58e8a3917eb0dfbdc0e3c5b54b2afd4683f6eb278d9b90fd3d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"PASS": 2, "symbolic": ["_____"]}
- `summary`: log evidence; size=47766 bytes; lines=594; PASS=2; symbolic=_____; tail=[nemu-ubuntu] heavy performance profile gate make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 107671
- `line_count`: 1963
- `sha256`: 8f157bd49151d9b94c4657d63b58c6193b00908009680590b71b952a86bdb341
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2341, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=107671 bytes; lines=1963; FAIL=7; PASS=2341; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=VE_EFFECT_OK_AFTER_TIMEOUT__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_PRERM__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTRM__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_AP...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 246352
- `line_count`: 4313
- `sha256`: a86f32ebf4292e9c209e052d156765be2af38c4d91a81ee6e74417c74456b50e
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=246352 bytes; lines=4313; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swbreak-insert OK PASS swbreak-hit S05 PASS swbreak-vcont-hit S05 PASS swbreak-pc...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1061
- `line_count`: 4
- `sha256`: 780500d138d1987d58e12715b598ec8d66e094a78f62dd3199f3a98dcbacef28
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=1061 bytes; lines=4; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/evidence/software-flow-contract.log nemu-ubuntu-stat...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/run-manifest.json

- `kind`: json
- `size_bytes`: 4362
- `line_count`: 108
- `sha256`: 2ce6989e4e9b0a092f6fa5a82ac1f3ac2fc5d87f8e8f96180e9159eaa13e0d06
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T18:25:00+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=4362 bytes; lines=108; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-vaddr-fault-inline-host-perf-profile/dispatch...
