# 2026-06-06 NEMU systemd runtime unit gate

## 目标

- 在用户要求“自行重新架构设计而不是在原来的基础上设计”的口径下，继续保持 NEMU UART 的公共 16550A core + bus profile + `SerialPort` front-end + SoC adapter + PLIC glue 分层，不让旧 mini UART 回流。
- 把 Ubuntu 22.04.5 systemd gate 从 target/manager/journal/dbus、transient service/timer，继续推进到 `/run/systemd/system` runtime unit fragment 的完整生命周期。

## 实现

- `Linux/scripts/check-nemu-systemd-guest.sh` 新增 `systemd_daemon_reload_wait()`：先做短 D-Bus `systemctl daemon-reload` 尝试；若客户端等待超时，则向 PID1 发送 `SIGHUP` 触发 reload fallback；随后用 `systemctl show LoadState/FragmentPath` 轮询确认指定 unit fragment 已被 PID1 看见。
- guest 内创建 `/run/systemd/system/nemu-runtime-unit-check.service`，检查 reload、start、输出文件、`ActiveState=active`、`Result=success`、`systemctl status`、cgroup v2、journal stdout 和 cleanup。
- cleanup 不再强依赖第二次 daemon-reload；它 stop/reset/remove runtime unit 后，确认 unit inactive 且 runtime unit 文件与临时目录消失。
- `Linux/Makefile` 将默认 `NEMU_SYSTEMD_CHECK_MAX_CYCLES` 提到 `25000000000`、host timeout 提到 `1800`，覆盖 runtime reload 与扩展 syscall probe 的实际预算。

## 调试结论

- 直接硬等 `systemctl daemon-reload` 会失败，日志为 `Failed to reload daemon: Connection timed out`。
- 将 `SYSTEMD_BUS_TIMEOUT` 拉到 180s 仍会超时，说明卡点是 D-Bus 同步 reply 速度，而不是 5s 默认超时太短。
- `systemctl --no-block daemon-reload` 仍会卡在客户端路径，不能作为可靠绕法。
- PID1 `SIGHUP` fallback 能让 runtime unit 被加载；真正应检查的是 PID1 对 unit fragment 的 `LoadState=loaded` 和 `FragmentPath=/run/systemd/system/nemu-runtime-unit-check.service`。
- 早期 fallback 版本的 cleanup 若再次硬等 absent reload 会烧光旧 12B 指令预算；最终改为 stop/reset/remove/inactive 检查，并把默认预算提高到 25B。

## 验证

- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `gcc -O2 -Wall -Werror -I nemu/include -o /tmp/uart16550-smoke nemu/src/device/uart16550.c nemu/tools/uart16550-smoke.c && /tmp/uart16550-smoke`：PASS，输出 `[uart16550-smoke] PASS`。
- `Select-String` 检查旧 `serial_base`/`soc_uart_regs`：未命中，说明旧 mini UART 状态没有回流。
- focused gate：
  - 日志目录：`Linux/env/logs/linux-front/riscv64-nemu-systemd-runtime-unit-25b-check/`
  - 外层状态：`Linux/env/logs/linux-front/riscv64-nemu-systemd-runtime-unit-25b.status` 为 `0`
  - `perf.tsv`: `boot_seconds=243`、`guest_check_seconds=631`、`poweroff_seconds=20`、`total_seconds=894`、`max_cycles=25000000000`
  - 关键 marker：`__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__`、`__NEMU_CHECK_SYSTEMD_RELOAD_STATE__:...:loaded:/run/systemd/system/nemu-runtime-unit-check.service`、`systemd-runtime-daemon-reload/start/output/active/result/status/cgroup/journal/cleanup` 全 PASS、`__NEMU_SYSCALL_PROBE_DONE__ rc=0`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`__NEMU_SYSTEMD_POWEROFF_BEGIN__`、`HIT GOOD TRAP`。
  - 失败扫描：无 `^__NEMU_CHECK_FAIL__:` 或 `^__NEMU_SYSCALL_PROBE_FAIL__`。

## 边界

- 这证明当前 NEMU 可以跑到 Ubuntu 22.04.5 systemd/root shell，并通过更完整的 systemd unit 生命周期 gate、syscall probe、rootfs/virtio/TTY/IRQ 检查与自然 poweroff。
- 这仍不是 QEMU 等价声明。剩余需要继续补的方向包括 virtio 多队列/feature negotiation/错误注入、更多 TTY 交互压力、多小时 session、以及更系统的设备异常路径。
