# NEMU Ubuntu systemd perf baseline

## 目标
- 把 NEMU 完整 Ubuntu guest-check 的“性能”从体感耗时变成稳定文件证据。
- 后续优化解释器、设备更新频率、UART/virtio 或 rootfs 路径时，可直接对比同字段 `perf.tsv`。

## 实现
- `Linux/scripts/check-nemu-systemd-guest.sh` 新增 `NEMU_SYSTEMD_PERF_LOG`，默认写到当前 log dir 的 `perf.tsv`。
- 新增 `Linux/scripts/check-nemu-performance-config.sh` 与 `make -C Linux ARCH=riscv64-nemu check-nemu-performance-config`，在 Ubuntu guest gate 启动前确认 `CONFIG_PERFORMANCE=y`，并拒绝 trace、difftest、watchpoint、BPU/统计、ASAN、runtime check、mem-random 与 RISC-V debug log 漏开。
- `__check-nemu-systemd-guest` 默认依赖该 performance gate；需要调试 trace 时显式使用 `NEMU_DEFCONFIG=riscv64-linux_debug_defconfig NEMU_PERFORMANCE_REQUIRED=0`。
- `perf.tsv` 字段：
  - `boot_seconds`
  - `guest_check_seconds`
  - `total_seconds`
  - `soak_seconds`
  - `fs_stress_mib`
  - `process_loops`
  - `block_parallel_jobs`
  - `block_job_mib`
  - `max_cycles`
- guest log 新增 `__NEMU_CHECK_GUEST_UPTIME_BEGIN__` 与 `__NEMU_CHECK_GUEST_UPTIME_END__`，用于区分 guest uptime 与 host wall time。

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `bash -n Linux/scripts/check-nemu-performance-config.sh`：PASS。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS。
- `make -C Linux ARCH=riscv64-nemu check-nemu-performance-config`：PASS，输出 `__NEMU_PERFORMANCE_CONFIG__:ok`。
- 负向验证：用 `nemu/configs/riscv64-linux_debug_defconfig` 作为 `NEMU_CONFIG` 调用 performance gate 会失败并报告缺少 `CONFIG_PERFORMANCE=y`。
- opt-out 验证：`NEMU_PERFORMANCE_REQUIRED=0 ... check-nemu-performance-config.sh` 输出 `__NEMU_PERFORMANCE_CONFIG__:skipped`。
- `make -C Linux ARCH=riscv64-nemu -n __check-nemu-systemd-guest`：dry-run 显示 guest gate 在启动 NEMU 前执行 `check-nemu-performance-config`。

## Baseline
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-check/perf.tsv`

```text
boot_seconds	guest_check_seconds	total_seconds	soak_seconds	fs_stress_mib	process_loops	max_cycles
234	74	308	20	4	16	12000000000
```

Guest uptime marker:
- `__NEMU_CHECK_GUEST_UPTIME_BEGIN__:347`
- `__NEMU_CHECK_GUEST_UPTIME_END__:471`

## 边界
- 这只是 host 墙钟基线，不是性能优化本身。
- 每次 host 负载、WSL 状态和 rootfs 内容都会影响绝对数值；后续 A/B 应尽量在同一机器、同一配置、同一 gate 下比较。
