# Task Report

## 基本信息

- task_id: 2026-06-24-npc-generator-static-fstab-real-rerun
- task_slug: npc-generator-static-fstab-real-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 在 static wrapper `wait` 监督模式下，只恢复 `systemd-fstab-generator` 真实执行，确认它是正常退出、信号退出还是卡住。
- scope: 构建独立 full-login-generator-static-fstab-real rootfs，`UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE=static`、`UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE=wait`，skip list 包含除 `systemd-fstab-generator` 外的已观察 generator；仍保持 login marker，不把该诊断作为完整 Ubuntu 完成路径。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| static-wait-impl | completed | `ysyx-npc-generator-skip.c`、build/check scripts | static parent `clone/execve/wait4` real-generator 监督模式 | static-wait-precheck-ok |
| npc-static-fstab-real-rerun | completed | static wait rootfs、500M cycles | `run.rc=2`，未到 login marker | evidence/npc-systemd-login-generator-static-fstab-real-rerun/ |
| analyze | completed | console/npc log | wrapper 执行的 fstab real child `exit=0`；但 `.ysyx-real` 留在扫描目录被 systemd 二次直跑并 `exit status 1` | evidence/postprocess-summary.txt |
| record | completed | rerun 结果 | 触发 clean-real-storage 修复和 clean 复跑 | dispatch-log.md |

## 当前阻塞点

- blockers: 本污染版对照已完成；完整 Ubuntu 22.04 login 仍未完成。
- risk: 只恢复一个 generator body 仍是诊断图，不等价于完整 systemd unit graph 或 login。

## 收尾结论

- final_result: fstab real child 可由静态父进程监督并正常退出；但 real binary 不能留在 systemd generator 扫描目录。
- evidence_summary: `BEGIN=13`、`STATIC_SKIP=12`、`REAL_STATUS=1 exit=0`、`real_direct_failed=1`、`duplicate_mount=1`、`segv=0`、`badaddr_0xda=0`、`login_done=0`。
