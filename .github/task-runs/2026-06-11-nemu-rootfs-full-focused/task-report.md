# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-rootfs-full-focused
- `task_slug`: nemu-rootfs-full-focused
- `graph_template`: rv64-ubuntu-rootfs-loop + regression-debug-loop
- `status`: completed
- `owner`: nemu + rv64-linux + software-flow
- `date`: 2026-06-11

## 任务目标

- 推进 full Ubuntu 22.04 rootfs 从静态 readiness 到 `check-nemu-systemd-guest-full` 真实 guest gate。
- 对失败点按 root cause 修复，并把缺口固化到低成本 e2e/静态合约。

## 根因与修复

1. full rootfs 首轮卡在 serial autologin，console 反复出现 `Module is unknown`。
   根因是 chrootless `dpkg-deb -x` overlay 后 PAM 模块分散在 `/lib/riscv64-linux-gnu/security` 与 `/usr/lib/riscv64-linux-gnu/security`，而 `login` 只搜索 `/lib/.../security`。旧 readiness 只检查目录存在，没有检查 `pam_unix.so` 等 login 必需模块。

2. 修复 PAM 后，full gate 跑过登录和大部分 guest check，但 dmesg 出现 `check-new-relea` 中 `python3.10` 的 `unhandled signal 4`。
   反汇编 `python3.10` 映射偏移 `0x1ae328`，对应 `fsqrt.d fa0,fs0`。根因是 NEMU RV64 FP 分发缺 `FSQRT.S/D`，full Ubuntu 的 Python/MOTD 路径真实触发该 ISA 缺口。

## 改动摘要

- `build-ubuntu-systemd-overlay.sh` 和 `build-ubuntu-rootfs.sh` 在 rootfs 生产阶段补齐 `/usr/lib/riscv64-linux-gnu/security/pam_*.so` 到 `/lib/riscv64-linux-gnu/security` 的相对 symlink。
- `check-ubuntu-rootfs.sh` 将 PAM gate 从“目录存在”升级为检查 `pam_unix.so`、`pam_deny.so`、`pam_permit.so`、`pam_env.so`、`pam_loginuid.so`、`pam_limits.so`。
- `nemu/src/isa/riscv64/inst/fp.c` 增加 `FSQRT.S/D`，负有限非零输入置 NV 并返回 canonical NaN。
- `Linux/tools` 增加 NEMU 专用 `smoke-nemu-fp-sqrt`，复用 `fp-sqrt-smoke.S`，裸机路径显式开启 `mstatus.FS` 并通过 syscon poweroff 形成 GOOD TRAP。
- `scripts/e2e/modules/nemu.sh` 将 PAM login module 和 NEMU FP sqrt smoke 纳入 `nemu-ubuntu` 静态生产守门与 slice contract。

## 验证证据

- `full-focused.log`: 首轮失败，`timeout waiting for log marker: root@ysyx-ubuntu2204:~#`，console 反复 `Module is unknown`。
- `full-rootfs-rebuild.log`: 重建 full rootfs 后 readiness PASS，含 6 个 PAM login module `OK`。
- `full-rootfs-check-after-fix.log`: 独立 `check-ubuntu-rootfs-full` PASS。
- `nemu-fp-sqrt-smoke.log`: `make -C Linux/tools smoke-nemu-fp-sqrt` PASS，日志含 `HIT GOOD TRAP`。
- `npc-fp-sqrt-smoke.log`: 原 NPC `smoke-fp-sqrt` PASS。
- `full-focused-rerun.log`: PAM 修复后登录和 guest check 继续推进，但暴露 `fsqrt.d` 对应的 Python SIGILL。
- `full-focused-final.log`: `make -C Linux ARCH=riscv64-nemu check-nemu-systemd-guest-full` PASS，perf 为 `boot=146s guest_check=749s poweroff=14s total=909s`。
- `final-console.log` / `final-nemu.log` / `final-perf.tsv` / `final-vda-direct-read-sha256.tsv`: 最终 guest gate 运行产物。
- `.github/task-runs/2026-06-11-nemu-rootfs-full-focused-fixes-e2e-2/`: `profile=nemu-ubuntu` PASS，静态 gate 跑到 `smoke-nemu-fp-sqrt` GOOD TRAP，并追踪 PAM login module 合约。

## 收尾结论

本切片闭合到 `ubuntu-rootfs` guest gate：full Ubuntu 22.04 rootfs 能在 NEMU RV64 systemd 路线中完成真实 focused check、rootfs 压力、virtio-blk/net runtime 检查、overlay backing 保护、关机和 GOOD TRAP。边界：这仍不是完整 QEMU VM 等价、SMP/PCI/TAP/NAT/snapshot/桌面 Ubuntu 或长期 soak signoff。
