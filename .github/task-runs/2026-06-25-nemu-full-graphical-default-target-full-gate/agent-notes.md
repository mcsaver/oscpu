# Agent Notes

- 本次切片把 NEMU full Ubuntu 22.04 的完成证据从 `systemd-analyze` multi-user boot audit 推进到默认 `graphical.target` / Graphical Interface target hard gate。
- 代码合同覆盖 rootfs path + dpkg ownership、guest `systemctl get-default=graphical.target`、`graphical.target` active，以及 `systemd-analyze --no-pager critical-chain graphical.target` rc/nonempty/target-seen。
- 静态首轮 `.github/task-runs/2026-06-25-nemu-full-graphical-default-target-contract/` 暴露 source 合同缺字面 `systemd-target-graphical.target`，已补显式 marker，并由 `.github/task-runs/2026-06-25-nemu-full-graphical-default-target-contract-rerun/` 复跑 PASS。
- 本 run 的 `nemu-dev-full-gate` 4 节点 PASS；console 行 150/371/372/409/1251/1256/1277-1284/1299/11128-11142/13607/13704 是主要复核入口，focused evidence 行 90/219/273/11733-11741/12007 是 hard-marker 入口。
- 大小写敏感负向扫描 task-report、focused evidence 与 console 未发现 `__NEMU_CHECK_FAIL__`、BAD TRAP、panic、Oops、SIGILL、Illegal instruction、unhandled signal、I/O error 或 budget stop；残留进程检查只有本次 `ps|rg` 自匹配。
- 边界：该切片证明 systemd 默认 target 与 Graphical Interface target 到达/active，并可审计 graphical critical-chain；仍不声明 GNOME/桌面 session、display manager、DRM/GPU/输入栈、外部网络、长期性能、QEMU 等价或完整 Ubuntu 2204 总目标完成。
