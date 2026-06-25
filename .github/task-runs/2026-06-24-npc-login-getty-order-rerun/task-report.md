# Task Report

## 基本信息

- `task_id`: `2026-06-24-npc-login-getty-order-rerun`
- `task_slug`: `npc-login-getty-order-rerun`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `dynamic-debug`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-24 +08:00`
- `updated_at`: `2026-06-24 +08:00`

## 任务目标

- `source_request`: `/goal 推进npc中完整ubuntu2204启动`
- `goal`: 继续推进 NPC/Verilator 上完整 Ubuntu 22.04 full-login gate。
- `scope`: 针对上一轮 full-login 中自动登录后无 marker、一次 longjmp abort、随后 udev coldplug no-limit 的新前沿，调整 serial-getty ordering：不等待 dev-ttyS0.device，但等 remount/tmpfiles-dev/udevd，再排在 systemd-udev-trigger coldplug 之前。

## 根因假设

上一轮 console 显示第一次 `root (automatic login)` 出现在 remount/tmpfiles-dev/coldplug 之前，随后出现 `*** longjmp causes uninitialized stack frame ***`，getty 被 systemd 重启；`.bash_profile` 的 `__NPC_LOGIN_CHECK_BEGIN__` 从未出现。因此 marker 未到的直接原因可能是 login/PAM/shell 太早启动，而不只是 coldplug 自身耗时。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| recall | completed | memory issue 96、上一轮 console | 新假设：login 过早启动导致 shell/profile 未开始 | 上一轮 console 行 226-282 |
| getty-order-fix | completed | build/check scripts | serial-getty waits remount/tmpfiles-dev/udevd but remains before udev-trigger | git diff、bash -n |
| npc-full-login-rerun | completed | 独立 full-login-getty-order rootfs、2.5B cycles | `run.rc=2`；getty ordering 生效，但登录 shell 在 marker 前 abort | evidence/npc-systemd-login-full-getty-order-rerun/ |
| record | completed | rerun 结果 | task-run 记录完成，memory 在后续 trace/profile 轮同步 | 本报告 |

## 当前阻塞点

- `blockers`: full Ubuntu login marker 仍未完成；本轮确认不再是 getty 过早等待 ttyS0 device，而是 root 自动登录后 shell/profile 链路在 marker 前失败。
- `risk`: 需要进一步插入 login wrapper/PAM/strace 级诊断，区分 `/bin/login`、PAM session 与 bash/profile。

## 收尾结论

- `final_result`: failed-forward。ordering 修复有效：console 行 259-261 依次出现 `Started Rule-based Manager for Device Events and Files`、`Started Serial Getty on ttyS0 for NPC login gate`、`Starting Coldplug All udev Devices`；随后 `login: root (automatic login)` 出现，但 `*** longjmp causes uninitialized stack frame ***` 在 `__NPC_LOGIN_CHECK_BEGIN__` 前触发。
- `evidence_summary`: `login-full-getty-order-rerun.rc=2`；负向扫描无旧 `SIGILL|Illegal instruction|fmadd|plymouth`；最终 PC `0xffffffff80135ab0` 映射到 `cp_new_stat at stat.c:?`。
