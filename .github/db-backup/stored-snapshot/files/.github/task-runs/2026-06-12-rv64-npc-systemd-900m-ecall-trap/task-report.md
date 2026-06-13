# RV64 NPC Systemd 900M And ECALL Trap Report

- 日期: 2026-06-12
- 范围: `npc/rv64`、`Linux/scripts/check-npc-systemd-guest.sh`、`scripts/e2e/modules/npc.sh`
- 目标: 继续向 NEMU 等价的 Ubuntu 22.04 root prompt/guest runtime gate 推进，同时把 banner 后长尾变成可复查证据。

## 结论

本轮没有宣称完整 Ubuntu 22.04 gate 完成。当前默认 systemd hard gate 的 900M-cycle 长跑仍未到 `root@ysyx-ubuntu2204:~#`，但已确认它不是旧 `rdinit=/init` 静态 probe，也不是 panic/Oops/Bad trap 类失败。

新增的进展是：NPC harness 现在具备 trap 层 U-mode syscall 观测。`NPC_USER_ECALL_TRACE=1` 默认只记录 U-mode ECALL trap (`cause=8`)；`NPC_USER_ECALL_TRACE_PRIV=1` 可按需打开 S/M ECALL，避免早期 SBI ECALL 把 trace limit 全部耗尽。

## 900M 当前 systemd 证据

- 日志目录: `Linux/env/logs/codex-npc-systemd-guest-900m-current`
- 运行结果: `run.rc=1`，原因是未等到 prompt，而不是仿真器崩溃。
- 已到达输出: ttyS0 console、virtio-blk vda、EXT4/VFS root mount、`Run /lib/systemd/systemd as init process`、`systemd 249.11-0ubuntu3.21 running in system mode`、`Welcome to Ubuntu 22.04.5 LTS`、hostname。
- 错误扫描: console/npc log 中未见 `Kernel panic`、`Oops`、`Bad trap`、`HIT BAD TRAP`、`BUG:`。
- 统计: cycles=900000000，commits=443145876，CPI=2.031，CLINT mtime=900000000。
- 末尾 PC 符号化: `__memset`、`kmem_cache_alloc`、`tcp_init`、`crc32_body` 一带。

## 代码与合约变更

- `npc/rv64/csrc/cpu/cpu-exec.cpp`
  - 新增 `maybe_log_ecall_trap()` 并挂到 `npc_handled_trap_event()`。
  - `NPC_USER_ECALL_TRACE=1` 默认 U-mode-only。
  - 新增 `NPC_USER_ECALL_TRACE_PRIV=1`，仅显式开启时记录 S/M ECALL。
  - `user_trace enabled` 日志打印 `ecall_priv=<0/1>`。
- `scripts/e2e/modules/npc.sh`
  - `e2e_npc_rv64_systemd_guest_check_contract` 静态守住 `maybe_log_ecall_trap`、`trap_hit=` 和 `NPC_USER_ECALL_TRACE_PRIV`。
- `.github/e2e/modules/npc.md`
  - RV64 Linux gate 文档补充 trap-layer syscall 观测口径。

## 验证

- `bash -n Linux/scripts/check-npc-systemd-guest.sh scripts/e2e/modules/npc.sh` PASS
- `make -C npc/rv64 -j2` PASS
- `scripts/agent-e2e.sh --validate-profile --profile rv64-linux` PASS
- manual `e2e_npc_rv64_systemd_guest_check_contract` PASS
- `NPC_USER_ECALL_TRACE=1 NPC_USER_ECALL_TRACE_LIMIT=16 make -C Linux ARCH=riscv64-npc smoke-sret-user-sv39` PASS，日志含 `trap_hit=1 ... mode=u cause=8`

## 下一步

用 `NPC_USER_PROGRESS_INTERVAL` 加 `NPC_USER_ECALL_TRACE=1` 继续跑更长的 `make check-npc-systemd-guest`，把 systemd banner 后到 serial-getty/root prompt 前的 syscall 阶段定位出来；若 U-mode syscall 仍推进正常，再把重点转向 kernel workqueue/timer/interrupt/virtio 或 getty service 激活路径。
