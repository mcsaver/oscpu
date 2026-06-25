# Task Report

## 基本信息

- task_id: 2026-06-24-npc-login-profile-rerun
- task_slug: npc-login-profile-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 验证 NPC login-marker 镜像最小化 /etc/profile 后，root autologin 是否能进入 /root/.bash_profile 并打出 done marker。
- scope: 使用独立 full-login-profile rootfs，trace 关闭，保留真实 agetty/login/PAM/bash 链路。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| minimal-profile | completed | trace run strace | NPC login-marker rootfs 写入最小 /etc/profile | bash -n, checker |
| npc-profile-rerun | completed | full-login-profile rootfs、2.5B cycles | `run.rc=2`；静态 rootfs PASS，但 runtime 停在 systemd hostname 后，未进入 udev/getty/login | evidence/npc-systemd-login-full-profile-rerun/ |
| record | completed | rerun 结果 | postprocess summary 与 memory 同步 | evidence/postprocess-summary.txt |

## 当前阻塞点

- blockers: full Ubuntu login marker 仍未完成；最小 `/etc/profile` rootfs 没有复现 trace 轮的 `/etc/profile` longjmp，但 runtime 在 systemd early boot 的 `Hostname set to <ysyx-ubuntu2204>` 后长期无进展。
- risk: profile 改动可能改变了 systemd 早期执行路径/镜像状态，不能把“没有看到 longjmp”写成 profile 根因已修；下一步需要定位 hostname 后的 PID1 等待点或改用更小诊断 rootfs 复现 shell/profile 修复。

## 收尾结论

- final_result: failed-forward。full-login-profile rootfs 静态检查 PASS，包含 `NPC login minimal /etc/profile`、getty ordering、PAM trim 与 preseed；真实 NPC runtime 进入 Linux 6.6、systemd 249.11、Ubuntu 22.04.5，但最后可见串口停在 `[1.504931] systemd[1]: Hostname set to <ysyx-ubuntu2204>`。等待约 28 分钟后手动 TERM 内层 `NpcSimTop` 让 runner 收尾，`run.rc=2`。
- evidence_summary: `evidence/postprocess-summary.txt` 显示 `Welcome to Ubuntu 22.04.5 LTS` present，`Started Rule-based Manager for Device Events and Files`、`Started Serial Getty on ttyS0 for NPC login gate`、`login: root (automatic login)`、`__NPC_LOGIN_CHECK_BEGIN__`、`__NPC_LOGIN_CHECK_DONE__ rc=0` 和 `longjmp causes uninitialized stack frame` 均 absent。
