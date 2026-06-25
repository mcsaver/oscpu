# Task Report

## 基本信息

- task_id: 2026-06-24-npc-generator-trace-rerun
- task_slug: npc-generator-trace-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 定位 systemd generator/direxec 阶段是否存在单个慢 generator 阻塞 NPC full-login 启动。
- scope: 构建独立 full-login-generator-trace rootfs，开启 `UBUNTU_ROOTFS_NPC_GENERATOR_TRACE=1`，保持真实 systemd generator 语义和 login marker，不以 trace wrapper 作为最终完成路径。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| generator-trace-impl | completed | build/check scripts | 可选 generator begin/end wrapper | bash -n |
| npc-generator-trace-rerun | completed | generator-trace rootfs、300M cycles | `run.rc=2`，未到 login marker | `evidence/npc-systemd-login-generator-trace-rerun/` |
| analyze | completed | console/npc log | systemd 已进入 generator 执行；5 个 BEGIN、0 个 END | `evidence/postprocess-summary.txt` |
| record | completed | rerun 结果 | 已记录本 task-run，待同步 memory | `task-report.md` |

## 当前阻塞点

- blockers: 完整 Ubuntu login marker 仍未达到；当前边界收敛到 systemd generator 执行窗口。
- risk: wrapper 只用于诊断，会增加 shell 启动开销；不能作为最终 full Ubuntu 完成证据。

## 收尾结论

- final_result: failed-forward；300M NPC 运行未完成 full login，但定位到 hostname 后继续进入 generator 执行。
- evidence_summary: 静态 rootfs readiness 通过，运行时打印 `friendly-recovery`、`systemd-bless-boot-generator`、`systemd-cryptsetup-generator`、`systemd-debug-generator`、`systemd-fstab-generator` 的 BEGIN；没有任何 generator END；未出现 `SIGILL`、`longjmp`、`panic`、getty/login 或 `__NPC_LOGIN_CHECK_DONE__`。末尾 PC `0xffffffff8040fdb6` 对应 `mas_next_slot` (`maple_tree.c:?`)。
