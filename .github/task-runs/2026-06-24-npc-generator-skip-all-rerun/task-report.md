# Task Report

## 基本信息

- task_id: 2026-06-24-npc-generator-skip-all-rerun
- task_slug: npc-generator-skip-all-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 用 generator skip-all 对照区分“真实 generator 执行窗口卡住”和“systemd generator 调度/等待框架卡住”。
- scope: 构建独立 full-login-generator-skip-all rootfs，开启 `UBUNTU_ROOTFS_NPC_GENERATOR_TRACE=1` 与 `UBUNTU_ROOTFS_NPC_GENERATOR_SKIP=all`；仍保持 login marker，不把 skip-all 作为最终 Ubuntu 完成路径。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| generator-skip-impl | completed | build/check scripts | 默认关闭的 generator skip wrapper；`UBUNTU_ROOTFS_NPC_GENERATOR_SKIP=all/name` | bash -n / static checker |
| npc-generator-skip-all-v1 | completed | skip-all rootfs、300M cycles | 无有效 SKIP/END；判为诊断污染 | evidence/npc-systemd-login-generator-skip-all-rerun/ |
| npc-generator-skip-all-v2-300m | completed | pure-shell skip wrapper、300M cycles | 越过前 5 个 generator，抵达 `systemd-getty-generator` | evidence/npc-systemd-login-generator-skip-all-v2-rerun/ |
| npc-generator-skip-all-v2-400m | completed | pure-shell skip wrapper、400M cycles | 11 BEGIN / 10 SKIP / 10 END；5 次 libc SIGSEGV；未到 login marker | evidence/npc-systemd-login-generator-skip-all-v2-400m-rerun/ |
| analyze | completed | console/npc log | generator 调度框架会继续推进；新边界是动态用户态进程退出/清理路径 SIGSEGV | evidence/postprocess-summary.txt |
| record | completed | rerun 结果 | memory/task-run 更新 | project-status / modules/npc / known-issues |

## 当前阻塞点

- blockers: 完整 Ubuntu 22.04 login 仍未完成；`__NPC_LOGIN_CHECK_DONE__ rc=0` 仍未出现。
- risk: skip-all 会改变真实 systemd unit 生成结果，只能用于定位 generator 执行边界，不能作为完整 Ubuntu 22.04 启动/login 完成证据。
- root_cause_boundary: 真实 generator trace 的 begin-only 不再应理解为 PID1 完全卡在调度前；pure-shell skip-all 能连续执行多个 generator wrapper，但多个动态 `/bin/sh` wrapper 在打印 `END rc=0` 后仍于 libc 同一偏移附近 SIGSEGV，下一步应隔离用户态退出/动态运行时路径。

## 收尾结论

- final_result: diagnostic-complete; goal still active / not boot-complete
- evidence_summary:
  - v1 skip-all wrapper 使用 `printf | tr` 外部命令/管道，早期 generator 诊断被污染，300M 内无有效 SKIP/END，后续不作为 guest 行为结论。
  - v2 改为纯 POSIX shell `case` 匹配后，静态 rootfs readiness PASS，checker 输出 `OK NPC systemd generator skip wrappers`。
  - v2 300M：前 5 个 generator `SKIP/END` 完成，推进到 `systemd-getty-generator` 的 `SKIP` 前后，说明 wrapper 框架能离开 begin-only。
  - v2 400M：`run.rc=2`，`BEGIN=11`、`SKIP=10`、`END=10`，最后一个只到 `systemd-system-update-generator BEGIN`；无 `__NPC_LOGIN_CHECK_DONE__`、`panic`、`SIGILL`、`longjmp`。
  - v2 400M 出现 5 次 `unhandled signal 11`，进程分别为 `friendly-recove`、`systemd-gpt-aut`、`systemd-hiberna`、`systemd-rc-loca`、`systemd-run-gen`；均为 `badaddr=0xda`，epc 落在对应 `libc.so.6` 基址后同一偏移附近。
  - v2 400M 末尾 `cycles=400000000`、`commits=192303539`、`simulation frequency=205705 inst/s`，最终 PC `0xffffffff802a86b0 -> tty_unthrottle`。
  - 收尾验证：`bash -n` / `git diff --check` PASS；v2 skip-all rootfs 静态 readiness PASS；默认 `ubuntu-22.04-riscv64-full.ext4` 无 `.ysyx-real` 或 generator marker 残留。
