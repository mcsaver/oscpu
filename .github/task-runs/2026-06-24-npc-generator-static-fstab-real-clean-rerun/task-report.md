# Task Report

## 基本信息

- task_id: 2026-06-24-npc-generator-static-fstab-real-clean-rerun
- task_slug: npc-generator-static-fstab-real-clean-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 修正 `.ysyx-real` 留在 systemd generator 扫描目录导致被二次执行的问题后，复跑只恢复 `systemd-fstab-generator` 真实执行的 static-wait 对照。
- scope: 构建独立 full-login-generator-static-fstab-real-clean rootfs，real generator 存放于 `/usr/local/lib/ysyx-npc-system-generators/`，扫描目录仅保留 wrapper；500M cycles 内确认 fstab wrapper-child 退出状态、是否仍出现裸 `.ysyx-real` direct run，以及是否到达 login marker。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| clean-real-storage | completed | 污染版 fstab-real 证据 | real generator 迁出扫描目录，checker 拒绝 `.ysyx-real` 残留 | `bash -n`、static wrapper compile PASS |
| npc-static-fstab-real-clean-rerun | completed | clean static-wait rootfs、500M cycles | `run.rc=2`，未到 login marker | evidence/npc-systemd-login-generator-static-fstab-real-clean-rerun/ |
| analyze | completed | console/npc log | fstab real child `exit=0`；无裸 `.ysyx-real` direct run；500M 终态用户态 PC `0x0000003faabb263c` | evidence/postprocess-summary.txt |
| record | completed | rerun 结果 | memory/task-run 更新 | dispatch-log.md |

## 当前阻塞点

- blockers: clean 复跑已完成；完整 Ubuntu 22.04 login 仍未完成，下一前沿在 generator 之后的 systemd/userspace 执行。
- risk: 只恢复一个 generator body 仍是诊断图，不等价于完整 systemd unit graph 或 login。

## 收尾结论

- final_result: `.ysyx-real` 扫描污染已消除，`systemd-fstab-generator` 真实执行在 static wait wrapper 下正常退出；500M 内仍未到 `__NPC_LOGIN_CHECK_DONE__ rc=0`。
- evidence_summary: `BEGIN=13`、`STATIC_SKIP=12`、`REAL_STATUS=1 exit=0`、`real_direct_failed=0`、`duplicate_mount=0`、`segv=0`、`badaddr_0xda=0`、`login_done=0`、`cycles=500000000`、`commits=288787275`。
