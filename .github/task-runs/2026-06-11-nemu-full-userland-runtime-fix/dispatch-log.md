# Dispatch Log

## 2026-06-11

- 发现 full-only userland runtime gate 未覆盖；新增 guest marker 和 wrapper marker。
- 首轮真实 full profile FAIL，定位 `/etc/ssh/sshd_config`、`syslog` 用户/组和 rsyslog dependency。
- 修复 rootfs 生产 defaults 与 readiness，重建 full rootfs。
- 二轮真实 full profile FAIL，定位 `sshd` privilege separation user 缺失。
- 修复 `sshd` 用户/组，重建 full rootfs。
- 三轮真实 full profile FAIL，定位 SSH host keys 缺失。
- 增加 `ssh-keygen -A -f "$ROOTFS"` 与 host key readiness，重建 full rootfs。
- 最终 full profile `.github/task-runs/2026-06-11-nemu-full-userland-runtime-real-run-after-hostkeys/` PASS。
