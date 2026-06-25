# Dispatch Log

## 基本信息

- `task_id`: `2026-06-24-npc-login-getty-order-rerun`
- `task_slug`: `npc-login-getty-order-rerun`
- `graph_template`: `rv64-ubuntu-rootfs-loop`

---

### [2026-06-24] `recall` - `completed`

- `action`: 复查上一轮 console、memory issue 96 和 rootfs 中 serial-getty/PAM/root profile。
- `outputs`: 第一次自动登录早于 remount/tmpfiles-dev 完成，longjmp 后 getty 重启；`.bash_profile` 存在但无 begin marker，说明 shell/profile 可能未开始。

### [2026-06-24] `getty-order-fix` - `completed`

- `action`: 调整 NPC login marker 模式下 serial-getty ordering，等待 `systemd-remount-fs.service`、`systemd-tmpfiles-setup-dev.service`、`systemd-udevd.service`，并保持 `Before=systemd-udev-trigger.service sysinit.target getty.target`。
- `outputs`: `bash -n` PASS；待重建 rootfs 并运行 full-login marker。

### [2026-06-24] `npc-full-login-rerun` - `completed`

- `action`: 使用独立 full-login-getty-order rootfs 复跑 2.5B-cycle NPC full-login marker。
- `outputs`: `login-full-getty-order-rerun.rc=2`；console 证明 getty ordering 生效并进入 root autologin，但登录 shell 在 `__NPC_LOGIN_CHECK_BEGIN__` 前触发 `*** longjmp causes uninitialized stack frame ***`。

### [2026-06-24] `record` - `completed`

- `action`: 将 rerun 边界写入 task report；后续 trace/profile 轮继续同步 memory。
- `outputs`: 旧 FMA/plymouth SIGILL 负扫 absent；最终 PC `0xffffffff80135ab0` 映射到 `cp_new_stat at stat.c:?`。
