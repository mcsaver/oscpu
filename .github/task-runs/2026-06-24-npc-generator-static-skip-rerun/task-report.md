# Task Report

## 基本信息

- task_id: 2026-06-24-npc-generator-static-skip-rerun
- task_slug: npc-generator-static-skip-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 用 libc-free 静态 generator skip wrapper 隔离 `/bin/sh`/glibc exit SIGSEGV 与 systemd generator 调度/等待路径。
- scope: 构建独立 full-login-generator-static-skip rootfs，开启 `UBUNTU_ROOTFS_NPC_GENERATOR_TRACE=1`、`UBUNTU_ROOTFS_NPC_GENERATOR_SKIP=all`、`UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE=static`；仍保持 login marker，不把 static skip 作为最终 Ubuntu 完成路径。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| static-skip-impl | completed | build/check scripts、`Linux/tools/ysyx-npc-generator-skip.c` | libc-free direct-syscall generator skip wrapper | static-wrapper-precheck-ok |
| npc-generator-static-skip-rerun | completed | static-skip rootfs、400M cycles | 13 BEGIN / 13 STATIC_SKIP / 13 SKIP / 13 END；无 libc SIGSEGV | evidence/npc-systemd-login-generator-static-skip-rerun/ |
| analyze | completed | console/npc log | static wrapper 消除了 shell v2 的 `badaddr=0xda` 崩溃，前沿转向动态 `/bin/sh`/glibc exit 或真实 generator body | evidence/postprocess-summary.txt |
| record | completed | rerun 结果 | memory/task-run 更新 | project-status / modules/npc / known-issues |

## 当前阻塞点

- blockers: 完整 Ubuntu 22.04 login 仍未完成；`__NPC_LOGIN_CHECK_DONE__ rc=0` 仍未出现。
- risk: skip-all 会改变真实 systemd unit 生成结果，只能定位 generator 子进程生命周期，不能作为完整 Ubuntu 22.04 启动/login 证据。
- root_cause_boundary: static skip-all 13/13 generator 成功结束且无 SIGSEGV，对照 shell v2 的 5 次 `libc.so.6 badaddr=0xda`，说明先前 skip wrapper 崩溃来自动态 shell/glibc exit 路径；真实 generator body 是否也触发同类路径仍需单 generator/static exec 对照。

## 收尾结论

- final_result: diagnostic-complete; goal still active / not boot-complete
- evidence_summary:
  - 静态 rootfs readiness PASS，checker 输出 `OK NPC systemd generator static skip wrappers`。
  - 400M runtime `run.rc=2`，无 `__NPC_LOGIN_CHECK_DONE__ rc=0`，所以完整 Ubuntu 22.04 login 未完成。
  - generator markers：`BEGIN=13`、`STATIC_SKIP=13`、`SKIP=13`、`END=13`，顺序到 `systemd-veritysetup-generator`。
  - 负向扫描：无 `unhandled signal 11`、无 `badaddr=0xda`、无 `panic`、无 `SIGILL`、无 `longjmp`。
  - 对照 shell v2 400M：`BEGIN=11`、`END=10`、`SIGSEGV=5`、`badaddr=0xda` 命中 10 行；static wrapper 明确移除了这条动态 exit 崩溃。
  - runtime tail：`cycles=400000000`、`commits=193060781`、`simulation frequency=206758 inst/s`，最终 PC `0xffffffff8013e280 -> step_into (namei.c:?)`。
  - 收尾验证：`bash -n` PASS；`ysyx-npc-generator-skip.c` 可编译为 RISC-V static soft-float ELF；static-skip rootfs readiness PASS；默认 `ubuntu-22.04-riscv64-full.ext4` 无 `.ysyx-real` 或 generator marker 残留；`git diff --check` PASS。
