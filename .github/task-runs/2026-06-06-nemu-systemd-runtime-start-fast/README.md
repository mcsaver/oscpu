# NEMU systemd runtime unit reload 快速收敛

## 背景

完整 Ubuntu guest-check 中 runtime unit 生命周期检查会创建 `/run/systemd/system/nemu-runtime-unit-check.service`，要求 PID1 reload 后能 start/status/cgroup/journal/cleanup。旧实现会在 `daemon-reload` D-Bus reply 超时后，继续反复调用 `systemctl show LoadState/FragmentPath` 等待 unit 可见；在 NEMU 下每轮 show 都可能触发 D-Bus timeout，focused gate 曾出现 `guest_check_seconds=964s`。

## 本轮设计

- `systemd_daemon_reload_request()` 只负责发出 `systemctl daemon-reload`，若 reply 慢则用 `kill -HUP 1` 走 PID1 reload 入口。
- `systemd_start_runtime_unit_after_reload()` 随后重试 `systemctl start` runtime unit，并以 `runtime.out` 出现作为“PID1 已看见 unit 且 unit 已执行”的强证据。
- 后续仍保留 `ActiveState/Result`、`systemctl status`、cgroup、journal 和 cleanup 检查，所以没有把 systemd 生命周期 gate 降级成只看文件存在。

## 验证

- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`: PASS。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh .github/task-runs/2026-06-06-nemu-systemd-runtime-start-fast/run-gate.sh`: PASS。
- Focused gate `run-gate.sh`: PASS，`run.status=0`。

`Linux/env/logs/linux-front/riscv64-nemu-systemd-runtime-start-fast/perf.tsv`:

```text
boot_seconds	guest_check_seconds	poweroff_seconds	total_seconds	soak_seconds	fs_stress_mib	fs_tree_files	process_loops	uart_rx_stress_lines	block_parallel_jobs	block_job_mib	max_cycles
236	525	21	782	0	1	8	2	128	1	1	25000000000
```

对比上一轮同类参数 `riscv64-nemu-uart-host-staging-rearch`：

- 旧 perf：`237/964/20/1221s`
- 新 perf：`236/525/21/782s`
- `guest_check_seconds` 减少 439s，总时长减少 439s。

关键 marker:

- `__NEMU_UART_RX_STRESS_COUNT__:128/128`
- `__NEMU_CHECK_PASS__:uart-rx-command-burst`
- `__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__:nemu-runtime-unit-check.service:present`
- `__NEMU_CHECK_SYSTEMD_RUNTIME_START_OBSERVED__:nemu-runtime-unit-check.service:4`
- `__NEMU_CHECK_PASS__:systemd-runtime-daemon-reload`
- `__NEMU_CHECK_PASS__:systemd-runtime-unit-start`
- `__NEMU_CHECK_PASS__:systemd-runtime-unit-output`
- `__NEMU_CHECK_PASS__:systemd-runtime-unit-cleanup`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `__NEMU_SYSTEMD_POWEROFF_BEGIN__`
- `reboot: Power down`
- `HIT GOOD TRAP`

## 边界

这是 guest-check 收敛策略和验证性能优化，不是 NEMU 指令执行速度优化。它保持了完整 systemd runtime unit 生命周期证据，但把“先长时间等 show 可见”改为“reload 后直接 start，并用真实 unit 执行结果证明可见”。
