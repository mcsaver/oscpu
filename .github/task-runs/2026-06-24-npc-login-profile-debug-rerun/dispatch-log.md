# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-login-profile-debug-rerun
- task_slug: npc-login-profile-debug-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] recall - completed

- action: 复查 `.github/AGENTS.md`、Copilot 指令、NPC memory 与 known issue 96。
- outputs: 确认完整 Ubuntu login marker 仍未完成；下一步应定位 `full-login-profile` 的 hostname 后 PID1 等待点。

### [2026-06-24] debug-rerun - completed

- action: 使用 systemd debug bootargs 与 NPC progress 对同一 rootfs 做短周期复跑。
- outputs: `run.rc=2`；到 200M 手动收束。证据显示 hostname 后 systemd 继续 fork `(sd-executor)` 与多个 `(direxec)`，不是 hostname 阶段死停。

### [2026-06-24] analyze - completed

- action: 将 profile-debug 证据和 generator-trace 证据串联。
- outputs: 下一边界收敛到 systemd generator 执行窗口。
