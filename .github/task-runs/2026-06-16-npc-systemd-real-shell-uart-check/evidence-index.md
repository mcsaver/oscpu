# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-npc-systemd-real-shell-uart-check
- `task_slug`: `npc-systemd-real-shell-uart-check`
- `profile`: 
- `asset_count`: 99
- `total_size_bytes`: 3575125

## 证据资产

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/autocheck-after-hook.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/autocheck-real-marker.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-after-hook/console.log

- `kind`: log
- `size_bytes`: 17300
- `line_count`: 244
- `sha256`: 9af2a95b97f3209fe1636d1003e440bbb3155445c97c78a5688990b28babc463
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=17300 bytes; lines=244; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-after-hook/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-after-hook/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 199
- `line_count`: 3
- `sha256`: 36827dc04e004515eb0560f720d893f9f586495a914464fa508af4d398b2e68b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: cmd evidence; size=199 bytes; lines=3; markers=<none>; tail=# NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck: # guest checks are emitted by the rootfs wrapper and the run is stopped only # after systemd/Ubuntu boot evidence appears, so no UART payload is injected.

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-after-hook/npc.log

- `kind`: log
- `size_bytes`: 17367
- `line_count`: 237
- `sha256`: e9bf4ab6093e10471fd27a73386aa3ff0c71178adabbb3f5f6e817fa47daacec
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=17367 bytes; lines=237; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-after-hook/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-after-hook/run.log

- `kind`: log
- `size_bytes`: 26759
- `line_count`: 365
- `sha256`: 5393f79ecf50f431f8339ed54f79c10efc7f8ebfba720695b8452f3558887c29
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"PASS": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=26759 bytes; lines=365; PASS=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=start: 2026-06-16T01:05:42+08:00 make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-npc BOOT=ubuntu-rootfs __check-npc-systemd-guest make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-real-marker/console.log

- `kind`: log
- `size_bytes`: 22861
- `line_count`: 327
- `sha256`: 447e32e7b082d62ab47aee6cb72449885a084bb5752002cf727d4261595a2968
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=22861 bytes; lines=327; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_AUTOCHECK_DONE__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-real-marker/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-real-marker/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 199
- `line_count`: 3
- `sha256`: 36827dc04e004515eb0560f720d893f9f586495a914464fa508af4d398b2e68b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: cmd evidence; size=199 bytes; lines=3; markers=<none>; tail=# NPC_SYSTEMD_GUEST_COMMAND_MODE=autocheck: # guest checks are emitted by the rootfs wrapper and the run is stopped only # after systemd/Ubuntu boot evidence appears, so no UART payload is injected.

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-real-marker/npc.log

- `kind`: log
- `size_bytes`: 23465
- `line_count`: 319
- `sha256`: 5fedde1ebbaa619fb570e5953e46eda124ec6f4610b96d600b7c83622447fc29
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=23465 bytes; lines=319; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_AUTOCHECK_DONE__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-real-marker/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-real-marker/run.log

- `kind`: log
- `size_bytes`: 33161
- `line_count`: 460
- `sha256`: 032e3f118ff8dc56ff933bdadff51ef6b85c9600c7d24c9907523f4621bed445
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"PASS": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=33161 bytes; lines=460; PASS=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_AUTOCHECK_DONE__; tail=start: 2026-06-16T08:58:33+08:00 make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-npc BOOT=ubuntu-rootfs __check-npc-systemd-guest make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-debug/console.log

- `kind`: log
- `size_bytes`: 36745
- `line_count`: 357
- `sha256`: 601b67f01623e4f84a3f69cda9f1f92ace1fe2caade39783aadbaec46db844ed
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=36745 bytes; lines=357; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-debug/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-debug/npc.log

- `kind`: log
- `size_bytes`: 36372
- `line_count`: 348
- `sha256`: 96d68de2df641ae1dd379b701b12de0415947980e0d85cca8d757fa5b0d44f33
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=36372 bytes; lines=348; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-debug/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff]...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-debug/run.log

- `kind`: log
- `size_bytes`: 43552
- `line_count`: 441
- `sha256`: 4dae31bcc4e3a0b474839755f9494d3a36ac5d62d767ae8b79b687f4ece0c83b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=43552 bytes; lines=441; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=start: 2026-06-16T02:44:46+08:00 make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ma...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-long/console.log

- `kind`: log
- `size_bytes`: 54685
- `line_count`: 568
- `sha256`: 7b1b5dbf9a8f7f22f1c02cd48fde6d65c7757e01872600c2e995cdd3669beb03
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=54685 bytes; lines=568; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-long/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-long/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-long/npc.log

- `kind`: log
- `size_bytes`: 53354
- `line_count`: 559
- `sha256`: b1d74d61b0b7ffd823ff61588d5018eb14c8bbc108800c5cb91ae370c3600bbe
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=53354 bytes; lines=559; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-long/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-long/run.log

- `kind`: log
- `size_bytes`: 83083
- `line_count`: 821
- `sha256`: c3b9fbe379bb83c79cae9ef09b81714b68f7865ba851a47df59c8f60bacf597a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=83083 bytes; lines=821; FAIL=2; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__; tail=Tasks Trace: Setting shift to 0 and lim to 1 rcu_task_cb_adjust=1. [ 0.016676] riscv: ELF compat mode unsupported [ 0.016848] ASID allocator using 16 bits (65536 entries) [ 0.018195] EFI services will not be available. [ 0.021094] devtmpfs: initialized [ 0....

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-sysinit-blocked/console.log

- `kind`: log
- `size_bytes`: 38586
- `line_count`: 377
- `sha256`: f40fe99df17fdc989e46aef35393bf579e7614639ee84995e363dae9ad54d31f
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=38586 bytes; lines=377; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000000008...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-sysinit-blocked/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-sysinit-blocked/npc.log

- `kind`: log
- `size_bytes`: 38289
- `line_count`: 368
- `sha256`: 5525700e14c84d215d4ea8570e2b582242d1d1df26cf59ee1edc169bca43a8c5
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=38289 bytes; lines=368; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-sysinit-blocked/run.log

- `kind`: log
- `size_bytes`: 66846
- `line_count`: 626
- `sha256`: eebdeaa1e76498f6293a4ebd699997244f8bc931a6f78747eb5e18df6296d302
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=66846 bytes; lines=626; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=se [ubuntu-rootfs-check] OK lp64d dynamic linker: /lib/ld-linux-riscv64-lp64d.so.1 [ubuntu-rootfs-check] OK PAM module path: /lib/riscv64-linux-gnu/security [ubuntu-rootfs-check] OK PAM login module: /lib/riscv64-linux-gnu/security/pam_unix.so [ubuntu-rootf...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-uart-input-not-consumed/console.log

- `kind`: log
- `size_bytes`: 50245
- `line_count`: 508
- `sha256`: 94dba858355ab6fb66898343f868751947275515ec959652989aa505a86a6588
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=50245 bytes; lines=508; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000000008...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-uart-input-not-consumed/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-uart-input-not-consumed/npc.log

- `kind`: log
- `size_bytes`: 48543
- `line_count`: 499
- `sha256`: b27b3f67ba15f288e0cdfa1d9e4c18b132e33ec962ca6e7b2e6510f14ef11e61
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=48543 bytes; lines=499; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-uart-input-not-consumed/run.log

- `kind`: log
- `size_bytes`: 78540
- `line_count`: 759
- `sha256`: 0920377a271d98e72e626d6006634b9c480d7b135ee66a2b2ada299e94ecd10b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=78540 bytes; lines=759; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=ons : time,rfnc,ipi,base,hsm,pmu,dbcn,fwft,legacy,sse Experimental SBI Extensions : none Domain0 Name : root Domain0 Boot HART : 0 Domain0 HARTs : 0* Domain0 Region00 : 0x0000000080040000-0x000000008005ffff M: (F,R,W) S/U: () Domain0 Region01 : 0x0000000080...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-wrapper-stall/console.log

- `kind`: log
- `size_bytes`: 10468
- `line_count`: 160
- `sha256`: 3966a550bf8c1b462845db0571944407dc9e382bc1abb98b36bd6d9d6d650139
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "_____"]}
- `summary`: log evidence; size=10468 bytes; lines=160; symbolic=__NPC_CONSOLE_SHELL_READY__,_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000000008...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-wrapper-stall/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-wrapper-stall/npc.log

- `kind`: log
- `size_bytes`: 11124
- `line_count`: 153
- `sha256`: 30ad29c6e3a46133380c982eae2a1956c9c18daef8054a9d0b78326ccb8caebf
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "_____"]}
- `summary`: log evidence; size=11124 bytes; lines=153; symbolic=__NPC_CONSOLE_SHELL_READY__,_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker-wrapper-stall/run.log

- `kind`: log
- `size_bytes`: 20068
- `line_count`: 281
- `sha256`: c623a0f507ebe380db425e0b4b3a063d5a15a7ea9ceb372ce450dbbeddac2dac
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=20068 bytes; lines=281; symbolic=__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_UART_CHECK_DONE__,_____; tail=start: 2026-06-16T03:36:31+08:00 make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-npc BOOT=ubuntu-rootfs __check-npc-systemd-guest make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/console.log

- `kind`: log
- `size_bytes`: 50270
- `line_count`: 507
- `sha256`: 47206b4d61cc7a55ea7ac59385f825c3837b4d1cdd4b3e22b98ac8a86ec693c6
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=50270 bytes; lines=507; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000000008...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log

- `kind`: log
- `size_bytes`: 48561
- `line_count`: 498
- `sha256`: 9acebb83f33250164caa713ce9f6286e7a3a25284b2a2a6f02a8ea6bc6fa8c40
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=48561 bytes; lines=498; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-ready-marker/run.log

- `kind`: log
- `size_bytes`: 78771
- `line_count`: 760
- `sha256`: 833a5ed86599c0a7791071dd7fb8d1f5dfbb7de2ab00249e87be6a722102a8d9
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=78771 bytes; lines=760; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=Name : root Domain0 Boot HART : 0 Domain0 HARTs : 0* Domain0 Region00 : 0x0000000080040000-0x000000008005ffff M: (F,R,W) S/U: () Domain0 Region01 : 0x0000000080000000-0x000000008003ffff M: (F,R,X) S/U: () Domain0 Region02 : 0x0000000010000000-0x000000001000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-rerun/console.log

- `kind`: log
- `size_bytes`: 46355
- `line_count`: 450
- `sha256`: 743254f414a7a6ac99be5e0e4b351937d7e005629a42092f9bafb601cc8a641e
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=46355 bytes; lines=450; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-rerun/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-rerun/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-rerun/npc.log

- `kind`: log
- `size_bytes`: 44256
- `line_count`: 442
- `sha256`: 46e91c16a648c9448f740a30ccc6e7cc4c1f89c75ccee8d489cde4c21ff26b7d
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=44256 bytes; lines=442; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-rerun/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfff...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-rerun/run.log

- `kind`: log
- `size_bytes`: 74404
- `line_count`: 695
- `sha256`: fa0f2e6d25468b8c376dee3313b5b33720564c2da97f1d1be51634ba04f09ae4
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=74404 bytes; lines=695; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=A/ysyx-workbench/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4' \ 2>&1 | tee '/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-rerun/console.log' [1;34m[log.c:145 npc...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-systemd-service/console.log

- `kind`: log
- `size_bytes`: 46004
- `line_count`: 448
- `sha256`: d063692818283babf07b3a19464d1e5344bb05bcd178d2b2219555c3b215ec37
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=46004 bytes; lines=448; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-systemd-service/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-systemd-service/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-systemd-service/npc.log

- `kind`: log
- `size_bytes`: 43882
- `line_count`: 439
- `sha256`: 463a1ced17a02972b7cee12f8f818fc9719d6a0aba45191d85cdf1b3385e9af5
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=43882 bytes; lines=439; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-systemd-service/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-systemd-service/run.log

- `kind`: log
- `size_bytes`: 73868
- `line_count`: 693
- `sha256`: 9930de40058f751cc317f80f528d76c78ce2f099d687f232a4f3f029832b9403
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=73868 bytes; lines=693; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=op' -b --progress=50000000 --no-diff --max=700000000 \ --log='/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest-systemd-service/npc.log' \ -i '/home/lyg/PA/ysyx-workbench/Linux/env/platform...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest/console.log

- `kind`: log
- `size_bytes`: 10280
- `line_count`: 158
- `sha256`: 1c87e9605c952c516ef615d2c5bcbaecf09e17a97ece2b838e935911f62b26ed
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=10280 bytes; lines=158; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest/npc-guest-check.cmd

- `kind`: cmd
- `size_bytes`: 1240
- `line_count`: 36
- `sha256`: f18d99b2753eb59a2538539b939b67afd6839df372843c8a47f0f32a626cd4a2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_FAIL__", "__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_UART_CHECK_DONE__"]}
- `summary`: cmd evidence; size=1240 bytes; lines=36; symbolic=__NPC_CHECK_FAIL__,__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_UART_CHECK_DONE__; tail=stty -echo 2>/dev/null || true PS1=; PS2=; PS4=; export PS1 PS2 PS4 echo __NPC_SYSTEMD_CHECK_BEGIN__ check_fail=0 pass() { echo "__NPC_CHECK_PASS__:$1"; } fail() { echo "__NPC_CHECK_FAIL__:$1"; check_fail=1; } uname -m | grep -q '^riscv64$' && pass uname-ri...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest/npc.log

- `kind`: log
- `size_bytes`: 10922
- `line_count`: 151
- `sha256`: acbc51343067820cfb5b2244dc024091c66e6d24c662bb2d3effb3d7ac815863
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=10922 bytes; lines=151; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff]...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-guest/run.log

- `kind`: log
- `size_bytes`: 19340
- `line_count`: 273
- `sha256`: d6a696d53f4a211b77c47fcb0b82d5378014f23b7ca5b66fe236411a4d001bdc
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_SYSTEMD_UART_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=19340 bytes; lines=273; symbolic=__NPC_SYSTEMD_UART_CHECK_DONE__,_____; tail=start: 2026-06-16T00:58:05+08:00 make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-npc BOOT=ubuntu-rootfs __check-npc-systemd-guest make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-access-trace/console.log

- `kind`: log
- `size_bytes`: 546200
- `line_count`: 3240
- `sha256`: c5374d8943865064a7aa25faf016572fafdfc8585d81c8fef77682bb67e1f7ec
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_TTY_READER_READY__", "_____"]}
- `summary`: log evidence; size=546200 bytes; lines=3240; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,__NPC_TTY_READER_READY__; tail=art_irq=1 plic_irq=1 [0m [1;34m[dpi.c:325 irq-trace] event=287 cycle=698564252 commit=385571822 uart_irq=1 plic_irq=0 [0m [1;34m[dpi.c:278 uart-access] access=2287 cycle=698564926 commit=385572115 read addr=0x000 wdata=0x0000000000000000 wstrb=0x0 rdata=0x0...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-access-trace/npc-tty-reader.cmd

- `kind`: cmd
- `size_bytes`: 24
- `line_count`: 1
- `sha256`: 96506608ac0a68e83bffe98fb3c2f051ecb5ae1291edd93c9607dcceef322b9a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_TTY_READER_PING__"]}
- `summary`: cmd evidence; size=24 bytes; lines=1; symbolic=__NPC_TTY_READER_PING__; tail=__NPC_TTY_READER_PING__

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-access-trace/npc.log

- `kind`: log
- `size_bytes`: 514876
- `line_count`: 3231
- `sha256`: bf558b44bbf0ab63f58486609fd2ad29dd8c4497f36b1814ca38dff0d0d554eb
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_TTY_READER_READY__", "_____"]}
- `summary`: log evidence; size=514876 bytes; lines=3231; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_AUTOCHECK_DONE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=ar='S' [dpi.c:278 uart-access] access=2266 cycle=698557426 commit=385568461 read addr=0x000 wdata=0x0000000000000000 wstrb=0x0 rdata=0x0000600113c20700 tx_valid=0 tx_data=0x53 char='S' [dpi.c:278 uart-access] access=2267 cycle=698557492 commit=385568500 rea...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-access-trace/run.log

- `kind`: log
- `size_bytes`: 574563
- `line_count`: 3493
- `sha256`: 9f07f92d0bfb51b219ab9978e9160730648a56392ce54984dfaedc3d34edab68
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 1, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_TTY_READER_DONE__", "__NPC_TTY_READER_READY__", "_____"]}
- `summary`: log evidence; size=574563 bytes; lines=3493; FAIL=1; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,__NPC_TTY_READER_DONE__; tail=000000003a wstrb=0x1 rdata=0x0000000000000000 tx_valid=1 tx_data=0x3a char=':' [0m : [1;34m[dpi.c:278 uart-access] access=2379 cycle=698750332 commit=385653730 write addr=0x000 wdata=0x0000000000000020 wstrb=0x1 rdata=0x0000000000000000 tx_valid=1 tx_data=0...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-loop/console.log

- `kind`: log
- `size_bytes`: 43494
- `line_count`: 444
- `sha256`: 09eec52ba83e30fd06d5fcbe7f6682de3b8b4ce6ea2d3ddb94cf0e271aa51c46
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_TTY_READER_READY__", "_____"]}
- `summary`: log evidence; size=43494 bytes; lines=444; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_SYSTEMD_AUTOCHECK_DONE__,__NPC_SYSTEMD_CHECK_BEGIN__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-loop/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000000008000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-loop/npc-tty-reader.cmd

- `kind`: cmd
- `size_bytes`: 24
- `line_count`: 1
- `sha256`: 96506608ac0a68e83bffe98fb3c2f051ecb5ae1291edd93c9607dcceef322b9a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_TTY_READER_PING__"]}
- `summary`: cmd evidence; size=24 bytes; lines=1; symbolic=__NPC_TTY_READER_PING__; tail=__NPC_TTY_READER_PING__

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-loop/npc.log

- `kind`: log
- `size_bytes`: 43202
- `line_count`: 435
- `sha256`: 98c63eecfa7746e0c0fe1481d58259fa3f5ca09c9602edeaa3e17aa2dbabf17e
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_TTY_READER_READY__", "_____"]}
- `summary`: log evidence; size=43202 bytes; lines=435; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_SYSTEMD_AUTOCHECK_DONE__,__NPC_SYSTEMD_CHECK_BEGIN__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-loop/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-loop/run.log

- `kind`: log
- `size_bytes`: 80033
- `line_count`: 806
- `sha256`: 35615c92993b4a647b412175dd4fde89e5eb0fe97aecc9434b6ed0ebb0fad82b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_TTY_READER_DONE__", "__NPC_TTY_READER_READY__", "_____"]}
- `summary`: log evidence; size=80033 bytes; lines=806; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_SYSTEMD_AUTOCHECK_DONE__,__NPC_SYSTEMD_CHECK_BEGIN__; tail=rity/pam_env.so [ubuntu-rootfs-check] OK PAM login module: /lib/riscv64-linux-gnu/security/pam_loginuid.so [ubuntu-rootfs-check] OK PAM login module: /lib/riscv64-linux-gnu/security/pam_limits.so [ubuntu-rootfs-check] OK e2scrub service entrypoint: /sbin/e2...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop/host-monitor.err

- `kind`: err
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: err evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop/host-monitor.out

- `kind`: out
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: out evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/console.log

- `kind`: log
- `size_bytes`: 49568
- `line_count`: 511
- `sha256`: 165baf3945128a7c799308c8873c6a9d5e622aa60d3795f1db386edeb180bd5c
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=49568 bytes; lines=511; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_AUTOCHECK_DONE__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/host-monitor.err

- `kind`: err
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: err evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/host-monitor.out

- `kind`: out
- `size_bytes`: 78466
- `line_count`: 769
- `sha256`: 2c5f2176c55644fa5a8639f60625f5d96c4cb9fd6862bb915bfb7bb8243c2bba
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_UART_PING_DONE__", "_____"]}
- `summary`: out evidence; size=78466 bytes; lines=769; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_AUTOCHECK_DONE__; tail=evice : uart8250 Platform HSM Device : --- Platform PMU Device : --- Platform Reboot Device : --- Platform Shutdown Device : --- Platform Suspend Device : --- Platform CPPC Device : --- Firmware Base : 0x80000000 Firmware Size : 321 KB Firmware RW Offset :...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/npc-uart-ping.cmd

- `kind`: cmd
- `size_bytes`: 94
- `line_count`: 4
- `sha256`: 4996dff497b8bf5b2433a7c2fb8cefca8717287e065acaf4d6b8c4c76ec1fe3d
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_UART_PING_BEGIN__", "__NPC_UART_PING_DONE__"]}
- `summary`: cmd evidence; size=94 bytes; lines=4; symbolic=__NPC_UART_PING_BEGIN__,__NPC_UART_PING_DONE__; tail=m=__NPC_UART_PING_BEGIN__ printf '%s\n' "$m" m=__NPC_UART_PING_DONE__ printf '%s rc=0\n' "$m"

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/npc.log

- `kind`: log
- `size_bytes`: 48485
- `line_count`: 502
- `sha256`: 6a040d04645f88fa0e740b987ef9cf0648a8dbce1762473978bd94120467c4ee
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=48485 bytes; lines=502; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_AUTOCHECK_DONE__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/run.log

- `kind`: log
- `size_bytes`: 78466
- `line_count`: 769
- `sha256`: 2c5f2176c55644fa5a8639f60625f5d96c4cb9fd6862bb915bfb7bb8243c2bba
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"FAIL": 2, "symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CHECK_UNAME__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_AUTOCHECK_DONE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_UART_PING_DONE__", "_____"]}
- `summary`: log evidence; size=78466 bytes; lines=769; FAIL=2; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CHECK_UNAME__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_AUTOCHECK_DONE__; tail=evice : uart8250 Platform HSM Device : --- Platform PMU Device : --- Platform Reboot Device : --- Platform Shutdown Device : --- Platform Suspend Device : --- Platform CPPC Device : --- Firmware Base : 0x80000000 Firmware Size : 321 KB Firmware RW Offset :...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/console.log

- `kind`: log
- `size_bytes`: 4823
- `line_count`: 83
- `sha256`: 9a04528cb06086720abba7e41ddd33e44dc56e52cf00442274b5982b934350b0
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "_____"]}
- `summary`: log evidence; size=4823 bytes; lines=83; symbolic=__NPC_CONSOLE_SHELL_READY__,_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/foreground.out

- `kind`: out
- `size_bytes`: 15148
- `line_count`: 211
- `sha256`: d89f9ca439391ee89ad6b22ca47872f286373032b50c3a4bb2e95f062625109f
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "__NPC_UART_PING_DONE__", "_____"]}
- `summary`: out evidence; size=15148 bytes; lines=211; symbolic=__NPC_CONSOLE_SHELL_READY__,__NPC_UART_PING_DONE__,_____; tail=start: 2026-06-16T09:55:00+08:00 cmd_file: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/npc-uart-ping.cmd make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' ma...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/npc-uart-ping.cmd

- `kind`: cmd
- `size_bytes`: 94
- `line_count`: 4
- `sha256`: 4996dff497b8bf5b2433a7c2fb8cefca8717287e065acaf4d6b8c4c76ec1fe3d
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_UART_PING_BEGIN__", "__NPC_UART_PING_DONE__"]}
- `summary`: cmd evidence; size=94 bytes; lines=4; symbolic=__NPC_UART_PING_BEGIN__,__NPC_UART_PING_DONE__; tail=m=__NPC_UART_PING_BEGIN__ printf '%s\n' "$m" m=__NPC_UART_PING_DONE__ printf '%s rc=0\n' "$m"

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/npc.log

- `kind`: log
- `size_bytes`: 4947
- `line_count`: 76
- `sha256`: 7d1b08c19691f89b067fc985483b8c8542c2fe6f68da1e41ab563c0bcb654d59
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "_____"]}
- `summary`: log evidence; size=4947 bytes; lines=76; symbolic=__NPC_CONSOLE_SHELL_READY__,_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/run.log

- `kind`: log
- `size_bytes`: 14999
- `line_count`: 211
- `sha256`: c30cb49d00e14624625746723c6d6901f20e989ff6ddf637b91d9943a25e2ca2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "__NPC_UART_PING_DONE__", "_____"]}
- `summary`: log evidence; size=14999 bytes; lines=211; symbolic=__NPC_CONSOLE_SHELL_READY__,__NPC_UART_PING_DONE__,_____; tail=start: 2026-06-16T09:55:00+08:00 cmd_file: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-rerun/npc-uart-ping.cmd make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' ma...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/console.log

- `kind`: log
- `size_bytes`: 11015
- `line_count`: 173
- `sha256`: 80a164811070f7784209e8145a1bb0aa3ad71929c29e9305a5dcf96dcb9813a4
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=11015 bytes; lines=173; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000080000...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/foreground.out

- `kind`: out
- `size_bytes`: 21287
- `line_count`: 301
- `sha256`: f2d9c2b142a1b24e1553686aa7907c0581bc1503c7bcd22228328ac6b569c75b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_UART_PING_DONE__", "_____"]}
- `summary`: out evidence; size=21287 bytes; lines=301; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=start: 2026-06-16T09:46:33+08:00 cmd_file: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/npc-uart-ping.cmd make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARC...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/foreground.rc

- `kind`: rc
- `size_bytes`: 20
- `line_count`: 1
- `sha256`: 3da7c1dd6827b75a42f224f2dffdbc0e1cdbd5f7e092f56b54ddc931de66399d
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=20 bytes; lines=1; markers=<none>; tail=foreground.exit=15

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/host-start.err

- `kind`: err
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: err evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/host-start.out

- `kind`: out
- `size_bytes`: 20151
- `line_count`: 282
- `sha256`: f90f255ca7fd90f59853854c9f7b2bbb6d1536600d8b63599a517d544b09ba1d
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "__NPC_UART_PING_DONE__", "_____"]}
- `summary`: out evidence; size=20151 bytes; lines=282; symbolic=__NPC_CONSOLE_SHELL_READY__,__NPC_UART_PING_DONE__,_____; tail=start: 2026-06-16T09:39:10+08:00 cmd_file: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/npc-uart-ping.cmd make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARC...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/host-wsl.pid

- `kind`: pid
- `size_bytes`: 11
- `line_count`: 1
- `sha256`: c147c467e9b55d1304f34ae2d44085af0d1697d56bf08b9cd1080524d6dc041f
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: pid evidence; size=11 bytes; lines=1; markers=<none>; tail=pid=12220

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/npc-uart-ping.cmd

- `kind`: cmd
- `size_bytes`: 94
- `line_count`: 4
- `sha256`: 4996dff497b8bf5b2433a7c2fb8cefca8717287e065acaf4d6b8c4c76ec1fe3d
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_UART_PING_BEGIN__", "__NPC_UART_PING_DONE__"]}
- `summary`: cmd evidence; size=94 bytes; lines=4; symbolic=__NPC_UART_PING_BEGIN__,__NPC_UART_PING_DONE__; tail=m=__NPC_UART_PING_BEGIN__ printf '%s\n' "$m" m=__NPC_UART_PING_DONE__ printf '%s rc=0\n' "$m"

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/npc.log

- `kind`: log
- `size_bytes`: 11762
- `line_count`: 166
- `sha256`: 59673498d030a9cac8703ebfe5ec53194b0131642a6f58bc711dc89c6148f6ec
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=11762 bytes; lines=166; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000b...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/run.log

- `kind`: log
- `size_bytes`: 21137
- `line_count`: 301
- `sha256`: 769c491a474bdf8702906f332a8cf7f13fc4224b3e41f470bd77d823a389c0e3
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_CONSOLE_SHELL_READY__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "__NPC_UART_PING_DONE__", "_____"]}
- `summary`: log evidence; size=21137 bytes; lines=301; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_CONSOLE_SHELL_READY__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__; tail=start: 2026-06-16T09:46:33+08:00 cmd_file: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow/npc-uart-ping.cmd make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARC...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/rebuild/rebuild.log

- `kind`: log
- `size_bytes`: 11980
- `line_count`: 168
- `sha256`: f90a589791fa17b7d35cefa6c18a7be3d88bef97339af8677af84e5f428d9029
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: log evidence; size=11980 bytes; lines=168; markers=<none>; tail=start: 2026-06-16T08:58:19+08:00 make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=systemd-minimal \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64.ext4' \ UBUN...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/wsl-start-probe.txt

- `kind`: txt
- `size_bytes`: 1
- `line_count`: 1
- `sha256`: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: txt evidence; size=1 bytes; lines=1; markers=<none>; tail=

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/wsl-start-probe3.txt

- `kind`: txt
- `size_bytes`: 9
- `line_count`: 1
- `sha256`: 2438c0d09f4fc7ecba4f102b08ff08a99c8ecfb44179cf5ee9d5de9a5124b7df
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: txt evidence; size=9 bytes; lines=1; markers=<none>; tail=probe3-ok

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/ready-marker-long.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/ready-marker.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/rebuild.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/rerun.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-autocheck-after-hook.sh

- `kind`: sh
- `size_bytes`: 711
- `line_count`: 24
- `sha256`: dfb6cad3594314c20fea1f29ca157efe941a1bf81fa12e5a0f14158a8bf0e433
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: sh evidence; size=711 bytes; lines=24; markers=<none>; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-autocheck-after-hook" mkdir -p "$log_dir" { echo "start: $(date -Is)" NPC_SYSTEM...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-autocheck-real-marker.sh

- `kind`: sh
- `size_bytes`: 664
- `line_count`: 23
- `sha256`: 26ebd6602f5fa78bd61e2af2a80e1909d12b7175b691eb8eaa538665b2cdab86
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: sh evidence; size=664 bytes; lines=23; markers=<none>; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-autocheck-real-marker" mkdir -p "$log_dir" { echo "start: $(date -Is)" NPC_SYSTE...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-ready-marker-long.sh

- `kind`: sh
- `size_bytes`: 800
- `line_count`: 26
- `sha256`: 427b561139b669cb1072d52481e42cb2a4c80d9c2426196f9df719f19e28de15
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: sh evidence; size=800 bytes; lines=26; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-guest-ready-marker-long" mkdir -p "$log_dir" { echo "start: $(date -Is)" NPC_SYS...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-ready-marker.sh

- `kind`: sh
- `size_bytes`: 789
- `line_count`: 26
- `sha256`: 9be5487ccfc63ebd1f8ad79bbe66ddd3661ff3324d1bf3203e83f005b979d40b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: sh evidence; size=789 bytes; lines=26; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-guest-ready-marker" mkdir -p "$log_dir" { echo "start: $(date -Is)" NPC_SYSTEMD_...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-rerun.sh

- `kind`: sh
- `size_bytes`: 760
- `line_count`: 26
- `sha256`: 158aba89464462b44fe3447d20fa27670b90ade6311753c42b708b805a8b7e65
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: sh evidence; size=760 bytes; lines=26; markers=<none>; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-guest-rerun" mkdir -p "$log_dir" { echo "start: $(date -Is)" NPC_SYSTEMD_CHECK_L...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-systemd-service.sh

- `kind`: sh
- `size_bytes`: 780
- `line_count`: 26
- `sha256`: fd0be5ebb6739ead8314591baa7e6da448f0035a54a0d5d79c723138f8380af2
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: sh evidence; size=780 bytes; lines=26; markers=<none>; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-guest-systemd-service" mkdir -p "$log_dir" { echo "start: $(date -Is)" NPC_SYSTE...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-tty-reader.sh

- `kind`: sh
- `size_bytes`: 3823
- `line_count`: 98
- `sha256`: 278aa6c6f3a56931ac9f7104b3374de9f0c7c7a39ea98a74f82b42e21ce377fe
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_TTY_READER_DONE__", "__NPC_TTY_READER_PING__", "__NPC_TTY_READER_READY__"]}
- `summary`: sh evidence; size=3823 bytes; lines=98; symbolic=__NPC_TTY_READER_DONE__,__NPC_TTY_READER_PING__,__NPC_TTY_READER_READY__; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_name=${NPC_TTY_READER_LOG_NAME:-npc-systemd-tty-reader-loop} rc_name=${NPC_TTY_READER_RC_NAME:-tty-reader-loop.rc}...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest-uart-ping-slow.sh

- `kind`: sh
- `size_bytes`: 1234
- `line_count`: 40
- `sha256`: bf6e29801e88aba82a2bf65cd76162a6c53e1694dc663e9709020670882fecfc
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__", "__NPC_UART_PING_BEGIN__", "__NPC_UART_PING_DONE__"]}
- `summary`: sh evidence; size=1234 bytes; lines=40; symbolic=__NPC_CONSOLE_SHELL_READY__,__NPC_UART_PING_BEGIN__,__NPC_UART_PING_DONE__; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_name=${NPC_UART_PING_LOG_NAME:-npc-systemd-uart-ping-slow} rc_name=${NPC_UART_PING_RC_NAME:-uart-ping-slow.rc} log_...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-guest.sh

- `kind`: sh
- `size_bytes`: 752
- `line_count`: 26
- `sha256`: 178ac8a7d05d39ffb887f1ec8d3b8940c3160637d065acc79a843450ac4b7b27
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: sh evidence; size=752 bytes; lines=26; markers=<none>; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-guest" mkdir -p "$log_dir" { echo "start: $(date -Is)" NPC_SYSTEMD_CHECK_LOG_DIR...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-rebuild.sh

- `kind`: sh
- `size_bytes`: 482
- `line_count`: 18
- `sha256`: 3eac7712a3550511581096e7015c952e7d7c42e760c384e185dc00ada3ecb309
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: sh evidence; size=482 bytes; lines=18; markers=<none>; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/rebuild" mkdir -p "$log_dir" { echo "start: $(date -Is)" make -C Linux ARCH=riscv64-npc ubun...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/run-systemd-debug.sh

- `kind`: sh
- `size_bytes`: 684
- `line_count`: 22
- `sha256`: 2d774393d4930b7a1642e1653382d1fcabaec54cb8d232c13cb3a46361478bba
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: sh evidence; size=684 bytes; lines=22; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=#!/usr/bin/env bash set -o pipefail cd /home/lyg/PA/ysyx-workbench run_dir=.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check log_dir="$run_dir/evidence/npc-systemd-debug" mkdir -p "$log_dir" { echo "start: $(date -Is)" env NPC_OOO_WINDOW=0 \ NP...

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/systemd-debug.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/systemd-service.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/tty-reader-access-trace.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/tty-reader-loop.hostpid

- `kind`: hostpid
- `size_bytes`: 7
- `line_count`: 1
- `sha256`: 7116dde486ffb25e32a2f04b0628ceb4fdacfca266a0ba248cec6f17e2a4a5b7
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: hostpid evidence; size=7 bytes; lines=1; markers=<none>; tail=30552

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/tty-reader-loop.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=1

### .github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/uart-ping-slow-loop2.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T07:09:04+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2
