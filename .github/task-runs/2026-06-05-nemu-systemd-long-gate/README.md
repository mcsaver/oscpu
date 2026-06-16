# NEMU Ubuntu systemd long gate

## 目标
- 在默认短 guest-check 之外，新增一条显式长稳态 gate，朝“长期运行稳定性、timer/interrupt 稳定性、rootfs 写回、tty/console 完整支持”推进。
- 不拖慢日常 smoke；长 gate 由 `make -C Linux check-nemu-systemd-guest-long` 单独触发。

## 实现
- `Linux/Makefile` 新增 `check-nemu-systemd-guest-long`。
- 默认参数：
  - `NEMU_SYSTEMD_CHECK_LOG_DIR=Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-long-check`
  - `NEMU_SYSTEMD_CHECK_MAX_CYCLES=30000000000`
  - `NEMU_SYSTEMD_CHECK_TIMEOUT=1800`
  - `NEMU_SYSTEMD_SOAK_SECONDS=120`
  - `NEMU_SYSTEMD_FS_STRESS_MIB=16`
  - `NEMU_SYSTEMD_PROCESS_LOOPS=64`
- `Linux/scripts/check-nemu-systemd-guest.sh` 新增：
  - `stty -F /dev/ttyS0 -a`
  - 写 marker 到 `/dev/ttyS0`
  - 写 marker 到 `/dev/console`
  - `mkfifo` + shell read/write IPC

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/Makefile Linux/scripts/check-nemu-systemd-guest.sh Linux/README.md Linux/env/README.md`：PASS。
- `make -C Linux check-nemu-systemd-guest-long`：PASS，用时约 370s。
- UART core/glue 拆层后复跑 `make -C Linux check-nemu-systemd-guest-long`：PASS，用时 380s，`perf.tsv` 为 `boot_seconds=240`、`guest_check_seconds=140`、`total_seconds=380`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`max_cycles=30000000000`。
- syscall probe 加入默认 guest-check 后复跑 `make -C Linux check-nemu-systemd-guest-long`：PASS，用时 411s，`perf.tsv` 为 `boot_seconds=244`、`guest_check_seconds=167`、`total_seconds=411`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`max_cycles=30000000000`；long log 中 `__NEMU_SYSCALL_PROBE_DONE__ rc=0` 和 `__NEMU_CHECK_PASS__:syscall-probe` 均出现。
- block/direct IO 加入默认 guest-check 后复跑 `make -C Linux check-nemu-systemd-guest-long`：PASS，用时 412s，`perf.tsv` 为 `boot_seconds=242`、`guest_check_seconds=170`、`total_seconds=412`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`max_cycles=30000000000`；long log 中 `vda-direct-read`、`vda-flushbufs`、`rootfs-direct-io`、`syscall-probe` 均 PASS。
- 并发 direct IO 加入默认 guest-check 后复跑 `make -C Linux check-nemu-systemd-guest-long` 时先发现 `/proc/stat intr` 单次 awk 采样可偶发读成 0，导致 `interrupts-stat-monotonic` false fail；脚本已改为 sed 提取首个数字并重试 3 次。修正采样后复跑 PASS，用时 433s，`perf.tsv` 为 `boot_seconds=242`、`guest_check_seconds=191`、`total_seconds=433`、`soak_seconds=120`、`fs_stress_mib=16`、`process_loops=64`、`block_parallel_jobs=4`、`block_job_mib=2`、`max_cycles=30000000000`；long log 中 4 个并发 job 均为 `2097152` 字节，`__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:8388608/8388608`，最终 `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

关键日志：
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-long-check/console.log`
- 可见 `__NEMU_CHECK_PASS__:ttyS0-stty`、`__NEMU_CHECK_TTYS0_WRITE__`、`__NEMU_CHECK_PASS__:ttyS0-write`、`__NEMU_CHECK_CONSOLE_WRITE__`、`__NEMU_CHECK_PASS__:console-write`、`__NEMU_CHECK_PASS__:fifo-ipc`、`__NEMU_CHECK_PASS__:fork-wait-loop`。
- 16MiB rootfs stress：`__NEMU_CHECK_FS_STRESS_BYTES__:16777216/16777216`，`__NEMU_CHECK_PASS__:rootfs-stress-copy-cmp`。
- 120s soak：原始验证为 `__NEMU_CHECK_SOAK_UPTIME__:450->646`、`__NEMU_CHECK_INTERRUPTS__:114915->164360`；UART core/glue 拆层后复验为 `__NEMU_CHECK_SOAK_UPTIME__:450->647`、`__NEMU_CHECK_INTERRUPTS__:114995->164460`；syscall probe 加入后复验为 `__NEMU_CHECK_SOAK_UPTIME__:484->681`、`__NEMU_CHECK_INTERRUPTS__:124313->173841`；block/direct IO 加入后复验为 `__NEMU_CHECK_SOAK_UPTIME__:493->690`、`__NEMU_CHECK_INTERRUPTS__:126633->176147`；并发 direct IO 加入并修正 interrupt 采样后复验为 `__NEMU_CHECK_SOAK_UPTIME__:515->713`、`__NEMU_CHECK_INTERRUPTS__:132771->182586`、`__NEMU_CHECK_PASS__:interrupts-stat-monotonic`。
- 收尾：`__NEMU_CHECK_PASS__:dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## 边界
- 这是中短期长稳态 gate，不是无限长期运行证明。
- 还未覆盖多小时运行、异常注入、virtio descriptor fuzz、多设备并发或 QEMU 级完整虚拟机能力。
