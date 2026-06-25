# Task Report

## 基本信息

- task_id: 2026-06-24-npc-generator-static-all-real-clean-rerun
- task_slug: npc-generator-static-all-real-clean-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 在 clean real-storage 基础上，让所有 systemd generator 都通过 static wait wrapper 真实执行，观察完整 generator 阶段是否干净闭合，并继续推进 full-login marker。
- scope: 构建独立 full-login-generator-static-all-real-clean rootfs，skip list 使用不会命中的 `__no_such_generator__` 哨兵，`UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE=wait`，500M fstab-clean 后升级到 1B cycles 对照。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| all-real-runner | completed | clean static wait wrapper、real storage fix | all-real 诊断 runner | run-generator-static-all-real-clean-rerun.sh |
| npc-static-all-real-clean-rerun | completed | all-real static-wait rootfs、1B cycles | `run.rc=2`，1B cycles 上限退出 | evidence/npc-systemd-login-generator-static-all-real-clean-rerun/ |
| analyze | completed | console/npc log | 13 个 generator 均真实执行并 exit=0；未到 login marker | evidence/postprocess-summary.txt |
| record | completed | rerun 结果 | memory/task-run 更新 | project-status、modules/npc、known-issues |

## 当前阻塞点

- blockers: 完整 Ubuntu 22.04 login 仍未完成；`__NPC_LOGIN_CHECK_DONE__ rc=0` 未出现。
- risk: static wait wrapper 仍是诊断包裹层；本轮证明所有 generator 真实 body 可干净闭合，但仍需要继续证明后续 systemd unit/getty/login/PAM/session。

## 收尾结论

- final_result: all-real static-wait generator 阶段干净闭合，但 full login 未完成。
- evidence_summary: rootfs readiness PASS；真实 NPC 1B cycles `run.rc=2`；`BEGIN=13`、`REAL_BEGIN=13`、`REAL_STATUS=13`、`END=13`，所有 real status 均为 `raw=0 exit=0`；`STATIC_SKIP=0`、`SKIP=0`；负扫 `segv=0`、`badaddr_0xda=0`、`panic=0`、`SIGILL=0`、`longjmp=0`、`duplicate_mount=0`、`systemd-fstab-generator.ysyx-real failed=0`。系统已越过 generator，进入 default target/unit 调度，看到 serial-getty slice、journald、module load、remount-root 等日志；最终 1B cycles 上限处 `ABORT at pc=0xffffffff800cc466`，`commits=547654024`，未出现 `__NPC_LOGIN_CHECK_DONE__ rc=0`。
