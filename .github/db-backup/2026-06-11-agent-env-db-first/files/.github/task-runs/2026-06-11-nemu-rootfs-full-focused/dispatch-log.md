# Dispatch Log

## RECALL

- 读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/nemu.md`。
- 读取 `.github/instructions/rv64-linux-bringup.instructions.md`、`.github/instructions/virtio-rootfs.instructions.md`、`.github/instructions/agent-e2e-workflow.instructions.md`、`.github/e2e/README.md`。
- 约束：full Ubuntu 结论必须分 gate；失败后按 root cause 修复；task-run 和 memory 必须记录。

## DISPATCH / ADAPT

1. 运行 `make -C Linux ARCH=riscv64-nemu check-nemu-systemd-guest-full`。
   结果：失败，`full-focused.log` 显示 serial autologin 后反复 `Module is unknown`。

2. 检查 rootfs PAM 配置和模块目录。
   发现：`/etc/pam.d/login` 引入 `common-auth/common-session`，但 `/lib/riscv64-linux-gnu/security` 只有 `pam_systemd.so` 和 `pam_cap.so`；`pam_unix.so` 等基础模块在 `/usr/lib/riscv64-linux-gnu/security`。

3. 修改 rootfs 生产脚本和 readiness check。
   结果：旧 full ext4 被新的 `check-ubuntu-rootfs-full` 准确判定缺 `pam_unix.so`、`pam_deny.so`、`pam_permit.so`、`pam_env.so`、`pam_loginuid.so`、`pam_limits.so`。

4. 重建 full rootfs。
   命令：`make -C Linux ARCH=riscv64-nemu ubuntu-rootfs-full-image`。
   结果：`full-rootfs-rebuild.log` PASS，PAM login module 全部 OK。

5. 再次运行 full focused gate。
   结果：`full-focused-rerun.log` 跑过登录和大部分 guest check，但 dmesg 发现 `python3.10` signal 4。

6. 反汇编 Python fault 地址。
   计算：`0x0000002ac3c21328 - 0x0000002ac3a73000 = 0x1ae328`。
   证据：`riscv64-linux-gnu-objdump` 显示 `0x1ae328: fsqrt.d fa0,fs0`。

7. 修改 NEMU RV64 FP 分发并补 NEMU FSQRT smoke。
   验证：`make -C Linux/tools smoke-nemu-fp-sqrt` PASS，`make -C Linux/tools smoke-fp-sqrt` PASS。

8. 第三次运行 full focused gate。
   结果：`full-focused-final.log` PASS；负向检索 `Module is unknown`、`unhandled signal`、`illegal instruction`、`sigill`、`__NEMU_CHECK_FAIL__` 无命中。

9. 运行模块化 e2e。
   命令：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-rootfs-full-focused-fixes-e2e`。
   结果：profile PASS，`nemu-ubuntu-static.log` 含 `smoke-nemu-fp-sqrt` GOOD TRAP，slice contract 含 PAM login module 和 FP sqrt Makefile target。

## VERIFY

- full rootfs readiness: PASS。
- NEMU FSQRT smoke: PASS。
- NPC FSQRT smoke: PASS。
- full focused guest gate: PASS。
- `nemu-ubuntu` e2e profile: PASS。

## RECORD

- 更新 `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/known-issues.md`。
- 本 task-run 保存三轮 focused 日志、final console/nemu/perf/hash 证据和 e2e 证据包链接。
