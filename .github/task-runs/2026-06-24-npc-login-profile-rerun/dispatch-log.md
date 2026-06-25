# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-login-profile-rerun
- task_slug: npc-login-profile-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] minimal-profile - completed

- action: 基于 trace 证据，将 NPC login-marker rootfs 的 /etc/profile 最小化，保留真实 login/PAM/bash 链路，把 marker 逻辑交给 /root/.bash_profile。
- outputs: build/check 脚本 bash -n 通过；checker 要求最小 profile 标记。

### [2026-06-24] npc-profile-rerun - completed

- action: 构建独立 full-login-profile rootfs 并运行 NPC full-login marker。
- outputs: `login-full-profile-rerun.rc=2`；静态 rootfs PASS，但 runtime 只到 systemd 249 / Ubuntu 22.04.5 / hostname，未进入 udev/getty/login。约 28 分钟无新串口后 TERM 内层 `NpcSimTop` 收尾。

### [2026-06-24] record - completed

- action: 抽取 console pattern 并写入 postprocess summary。
- outputs: `Welcome to Ubuntu 22.04.5 LTS` present；`Started Serial Getty on ttyS0`、`login: root (automatic login)`、`__NPC_LOGIN_CHECK_DONE__ rc=0` 与 `longjmp causes uninitialized stack frame` 均 absent。
