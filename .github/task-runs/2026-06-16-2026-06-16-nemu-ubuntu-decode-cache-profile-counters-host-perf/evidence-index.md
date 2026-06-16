# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf
- `task_slug`: 2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf
- `profile`: nemu-ubuntu-profile
- `asset_count`: 22
- `total_size_bytes`: 8592211714

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/console.log

- `kind`: log
- `size_bytes`: 33084
- `line_count`: 417
- `sha256`: 80c71d62129a711a1dcf07c9e530e80faa90c36945d3adad4c986c975ba9fab7
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=33084 bytes; lines=417; symbolic=_____; tail=OpenSBI v1.8 ____ _____ ____ _____ / __ \ / ____| _ \_ _| | | | |_ __ ___ _ __ | (___ | |_) || | | | | | '_ \ / _ \ '_ \ \___ \| _ < | | | |__| | |_) | __/ | | |____) | |_) || |_ \____/| .__/ \___|_| |_|_____/|____/_____| | | |_| Platform Name : YSYX NPC RV...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/host-profiler.txt

- `kind`: txt
- `size_bytes`: 1564
- `line_count`: 36
- `sha256`: 821be747e91739dd3c94a007c9f3a410ef43df5ef56599be953d907c1ab8f08c
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"WARN": 2}
- `summary`: txt evidence; size=1564 bytes; lines=36; WARN=2; tail=perf.record.requested=1 perf.record.freq=99 perf.source=system perf.path=/usr/bin/perf perf.status=unavailable WARNING: perf not found for kernel 6.6.87.2-microsoft You may need to install the following packages for this specific kernel: linux-tools-6.6.87....

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/perf-report.err

- `kind`: err
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: err evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/perf-report.txt

- `kind`: txt
- `size_bytes`: 9043
- `line_count`: 148
- `sha256`: 1ada8661b6ef6e6f32bedabb73649879b99de67baace4ecb3ac5e8edaf8b1442
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"symbolic": ["__GI___"]}
- `summary`: txt evidence; size=9043 bytes; lines=148; symbolic=__GI___; tail=# To display the perf.data header info, please use --header/--header-only options. # # # Total Lost Samples: 0 # # Samples: 2K of event 'task-clock:upppH' # Event count (approx.): 21040403830 # # Overhead Command Shared Object Symbol IPC [IPC Coverage] # .....

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/perf-smoke.out

- `kind`: out
- `size_bytes`: 243
- `line_count`: 11
- `sha256`: 7dc111419a452770de3f4816a2ab49d220ff187a16e0eac2bd5f2c137316aadd
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: out evidence; size=243 bytes; lines=11; markers=<none>; tail=Performance counter stats for 'true': 0.45 msec task-clock:u # 0.275 CPUs utilized 0.001623924 seconds time elapsed 0.000991000 seconds user 0.000000000 seconds sys

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/perf.data

- `kind`: data
- `size_bytes`: 1741220
- `line_count`: 11621
- `sha256`: e99287b36596e4d8e9f3ef973bf7415d5655802ba7daa0f2f35ea05c3ada7f98
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: data evidence; size=1741220 bytes; lines=11621; markers=<none>; tail=B� grep B� B� }�/U� h B� B� �T �\ 0 @ 0 �� � r* /usr/bin/grep B� B� <�/U� � B� B� p��5s � 0 4r ���q /usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 B� B� E+0U� ` B� B� ЍM� [vdso] B� B� �D0U� � B� B� �x�5s � 0 l} ���3 /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/profile-command.txt

- `kind`: txt
- `size_bytes`: 481
- `line_count`: 18
- `sha256`: 9eb77a5db514ae215b0f1c078b1c609c29686e04cc8bdda934fc294205f82685
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: txt evidence; size=481 bytes; lines=18; markers=<none>; tail=repo_root=/home/lyg/PA/ysyx-workbench rootfs_flavor=full rootfs_image=/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4 max_cycles=1000000000 progress=50000000 tb_max_inst=32 opcode_mix=0 stop_detail=0 hos...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/profile-run.log

- `kind`: log
- `size_bytes`: 47648
- `line_count`: 592
- `sha256`: 70eeaed129d65c4c1e7f10c682595362c923281d153d999808a4a936bfba3d3f
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=47648 bytes; lines=592; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/profile-summary.txt

- `kind`: txt
- `size_bytes`: 8075
- `line_count`: 221
- `sha256`: f5113650cd4b42f812c01bc0b3156cbd99ac18c3de27e4bab74c1bbbea3087ea
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: txt evidence; size=8075 bytes; lines=221; markers=<none>; tail=# NEMU Ubuntu Profile Summary profile.available=1 profile.clint.host_time_reads=1981385 profile.cpu.basic_block_avg_inst_x100=2898 profile.cpu.basic_block_inst=1000000000 profile.cpu.basic_blocks=34502488 profile.cpu.decode_cache.fill_rvc=51373000 profile.c...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-profile/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 2852
- `sha256`: 80d3116d7d7ac91afa04b56ff844ffe1dc023084254baf6ba9e97be0e4efa567
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=2852; markers=<none>; tail=

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 887
- `line_count`: 12
- `sha256`: 6e02a626a684c2dd233c354025c28b8c8dd35eb9e15410e06f1ad94ff0525983
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: log evidence; size=887 bytes; lines=12; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8304
- `line_count`: 99
- `sha256`: a9ffcb3618cc8797db14514404c0dfa65094ccb4584c47a0808044ff27548c30
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: log evidence; size=8304 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7997
- `line_count`: 92
- `sha256`: 4c6fe4e3d54b61a0289a6302ae13ca4403dce4062b8b604c1ee1550cf7178b25
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: log evidence; size=7997 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7265
- `line_count`: 68
- `sha256`: 0bc3f8ef6b545a96ad51b2dcb6e50d200a02ddb089cb3b1f47fdca17521fb1cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {}
- `summary`: log evidence; size=7265 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-ubuntu-profile.log

- `kind`: log
- `size_bytes`: 48041
- `line_count`: 595
- `sha256`: 6fc49c4551c1c2e35293ed0301427534d7e96be5a1b9e8db418e34fae86522e1
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"PASS": 2, "symbolic": ["_____"]}
- `summary`: log evidence; size=48041 bytes; lines=595; PASS=2; symbolic=_____; tail=[nemu-ubuntu] heavy performance profile gate make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 108246
- `line_count`: 1972
- `sha256`: 4eda4fd450840f264a8c510f33b9e723a48325308ee51dec3028ce15323cb1d2
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2344, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=108246 bytes; lines=1972; FAIL=7; PASS=2344; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=IRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_REMOVE_LOG_BEGIN__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_PURGE_START__ PASS check-nemu-systemd-guest...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 246494
- `line_count`: 4315
- `sha256`: bb73b77e413751c841e9e563d8eaaddb9acd212ad1d80747966e3bbbf82bdcd6
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=246494 bytes; lines=4315; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swbreak-insert OK PASS swbreak-hit S05 PASS swbreak-vcont-hit S05 PASS swbreak-pc...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1073
- `line_count`: 4
- `sha256`: 1a6a12d4b512acb98a59743536a2a97491f27733cfefcb442618b6d086831e7a
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=1073 bytes; lines=4; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/evidence/software-flow-contract.log nemu-ubuntu-s...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/run-manifest.json

- `kind`: json
- `size_bytes`: 4410
- `line_count`: 108
- `sha256`: 103c3e33e13f51a149c13e1807a6dee77dd69f80feedcf28fbb6933413088f28
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T19:22:40+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=4410 bytes; lines=108; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-cache-profile-counters-host-perf/di...
