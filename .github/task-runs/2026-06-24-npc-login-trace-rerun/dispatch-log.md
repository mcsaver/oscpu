# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-login-trace-rerun
- task_slug: npc-login-trace-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] trace-wrapper - completed

- action: 添加 UBUNTU_ROOTFS_NPC_LOGIN_TRACE=1 诊断开关，agetty 经 /usr/local/sbin/ysyx-npc-login-trace 调用真实 /bin/login。
- outputs: build/check 脚本 bash -n 通过；静态 checker 可要求 wrapper 与 --login-program。

### [2026-06-24] npc-trace-rerun - completed

- action: 构建独立 full-login-trace rootfs 并运行 NPC full-login marker。
- outputs: `login-full-trace-rerun.rc=2`；trace wrapper 进入真实 `/bin/login -f root`，父 login rc=0，但 shell 子进程在读取 `/etc/profile` 后 SIGABRT，marker 未到。

### [2026-06-24] record - completed

- action: 保存 trace evidence 并把 root cause 假设从 getty/PAM 父进程收窄到 bash login shell profile 处理。
- outputs: strace tail 保留于 `evidence/npc-systemd-login-full-trace-rerun/console.log`；旧 `SIGILL|Illegal instruction|fmadd|plymouth` absent。
