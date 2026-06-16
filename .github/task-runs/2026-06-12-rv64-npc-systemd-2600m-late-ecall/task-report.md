# RV64 NPC systemd 2.6B late ecall hard gate

## 目标

继续推进 NPC RV64 默认 Ubuntu 22.04 rootfs/systemd 路线，使用 NEMU-style guest-side hard gate 验证是否能到达真实 `root@ysyx-ubuntu2204:~#`，释放 UART RX guest 检查脚本，并命中 `__NPC_SYSTEMD_CHECK_DONE__ rc=0`。

## 运行配置

- 证据目录：`Linux/env/logs/codex-npc-systemd-guest-late-ecall-2600m`
- `NPC_SYSTEMD_CHECK_MAX_CYCLES=2600000000`
- `NPC_SYSTEMD_HOST_TIMEOUT=15000`
- `NPC_SYSTEMD_PROGRESS=50000000`
- `NPC_USER_TRACE_MIN_COMMIT=90000000`
- `NPC_USER_PROGRESS_INTERVAL=20000000`
- `NPC_USER_PROGRESS_LIMIT=256`
- `NPC_USER_ECALL_TRACE=1`
- `NPC_USER_ECALL_MIN_COMMIT=900000000`
- `NPC_USER_ECALL_TRACE_LIMIT=8192`

## 结果

- `run.rc=1`，hard gate 仍未通过。
- 真实 guest prompt 未出现；`run.log` 中 `root@ysyx-ubuntu2204:~#` 的 3 次命中只来自 harness prompt wait 和 UART RX wait 配置，`console.log` 中也只有 UART 等待日志。
- `__NPC_SYSTEMD_CHECK_DONE__` 未出现。
- 未见 `Kernel panic`、`Oops`、`Bad trap`、`HIT BAD TRAP`、`BUG:`。

## 关键统计

- cycles=2600000000
- commits=1194223551
- CPI=2.177
- CLINT mtime=2600000000，mtime-cycles=+0，match=yes
- simulation frequency=198286 inst/s

## Console 进展

本轮已复现并越过 systemd PID1、Ubuntu 22.04 banner、kernel module load、EXT4 remount、kernel variables、random seed、journal service 等阶段。末尾长期停在 systemd start job 刷新：

- `(1 of 2) A start job is running for ... udev Devices`
- `(2 of 2) A start job is running for ... System Users`
- guest 计时推进到约 `2min 30s / no limit`

这说明 2.6B 预算下仍未到 serial login/root shell，缺口集中在 udev coldplug / create users / getty 前后，而不是早期 kernel handoff。

## U-mode ecall trace

`NPC_USER_ECALL_MIN_COMMIT=900000000` 生效，8192 条 quota 被填满：

- first: trap_hit=1, commit=900007109, syscall=57
- last: trap_hit=8192, commit=1028070429, syscall=57
- top syscall IDs: 56=2177, 57=1963, 79=1514, 63=402, 78=304, 48=243, 29=222, 178=168, 22=160, 278=158

trace 在 1.028B commits 已耗尽，而本轮最终到 1.194B commits；下一轮如果继续用 ecall trace，建议把 `NPC_USER_ECALL_MIN_COMMIT` 后移到 1.08B 或 1.15B。

## PC 符号化

- final PC `0xffffffff80144d86` -> `d_set_d_op`
- tail commit path: `__d_alloc -> d_set_d_op`
- sampled hot PCs include `__memset`, `tcp_init`, `do_seccomp`

当前仍没有明确 RTL trap 证据，更像 systemd/udev 文件系统遍历、设备冷插拔或服务等待长尾。

## 后续建议

1. 把 late ecall window 后移到 `NPC_USER_ECALL_MIN_COMMIT=1080000000` 或 `1150000000`，覆盖 1.028B 之后到 1.194B+ 的 udev/create-users 阶段。
2. 增加更窄的 systemd/udev console marker 或 guest-side init instrumentation，优先确认 `udev Devices` 是纯仿真慢，还是某个设备节点/内核事件永远未完成。
3. 完整 gate 仍以真实 `root@ysyx-ubuntu2204:~#` 和 `__NPC_SYSTEMD_CHECK_DONE__ rc=0` 为准，不能用 harness prompt wait 字符串替代。
