# Task Report

## 基本信息

- task_id: 2026-06-24-npc-login-trace-rerun
- task_slug: npc-login-trace-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 在 getty ordering 已修正后，定位 root autologin 进入 shell/profile 前的 longjmp abort。
- scope: 使用独立 full-login-trace rootfs，开启 NPC login trace wrapper，经真实 /bin/login 路径收集 argv、rc 和 strace 尾部。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| trace-wrapper | completed | build/check scripts | UBUNTU_ROOTFS_NPC_LOGIN_TRACE=1 可生成 /usr/local/sbin/ysyx-npc-login-trace | bash -n |
| npc-trace-rerun | completed | full-login-trace rootfs、2.5B cycles | `run.rc=2`；真实 `/bin/login -f root` fork 出 shell 子进程，子进程读取 `/etc/profile` 后 SIGABRT | evidence/npc-systemd-login-full-trace-rerun/ |
| record | completed | trace rerun 结果 | task-run 记录完成，memory 在 profile 轮后同步 | 本报告 |

## 当前阻塞点

- blockers: login marker 仍未完成；trace 已把直接失败点从 getty/PAM 父进程收窄到 bash login shell 读取 `/etc/profile`。
- risk: wrapper/strace 只用于诊断，不应作为最终完成路径；后续修复仍需回到真实 agetty/login/PAM/bash 链路。

## 收尾结论

- final_result: completed diagnostics。`ysyx-npc-login-trace` 打印 `__NPC_LOGIN_TRACE_BEGIN__ argc=2 argv=-f root`、TTY `/dev/ttyS0` 和 `/usr/bin/login`，父 login 最终 `__NPC_LOGIN_TRACE_LOGIN_RC__:0`，但 shell 子进程 `87` 被 SIGABRT。
- evidence_summary: strace tail 显示子进程打开并读取 `/etc/profile` 后输出 `*** longjmp causes uninitialized stack frame ***: terminated`，随后 `tgkill(..., SIGABRT)`；`__NPC_LOGIN_CHECK_BEGIN__` / done marker 仍 absent；旧 `SIGILL|Illegal instruction|fmadd|plymouth` absent。
