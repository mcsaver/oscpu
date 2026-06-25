# Task Report

## 基本信息

- task_id: 2026-06-24-npc-login-profile-debug-rerun
- task_slug: npc-login-profile-debug-rerun
- graph_template: rv64-ubuntu-rootfs-loop
- graph_mode: dynamic-debug
- status: completed
- owner: codex
- started_at: 2026-06-24 +08:00
- updated_at: 2026-06-24 +08:00

## 任务目标

- source_request: /goal 推进npc中完整ubuntu2204启动
- goal: 定位 `full-login-profile` rootfs 在 systemd hostname 后未继续进入 udev/getty/login 的等待点。
- scope: 复用独立 full-login-profile rootfs，不改变完成 marker；只打开 systemd console debug、NPC progress 和短周期边界收集 evidence。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| recall | completed | known issue 96、profile rerun evidence | 当前边界：hostname 后长期无串口输出，marker 未到 | memory/task-runs |
| debug-rerun | completed | full-login-profile rootfs、systemd debug bootargs、900M cycles | `run.rc=2`，200M 后手动收束 | `evidence/npc-systemd-login-full-profile-debug-rerun/` |
| analyze | completed | console/npc log | hostname 后 systemd 继续 fork `(sd-executor)` 与多个 `(direxec)` | console.log |
| record | completed | rerun 结果 | 已记录本 task-run，后续由 generator-trace 细化 | `task-report.md` |

## 当前阻塞点

- blockers: 完整 Ubuntu login marker 仍未达到；hostname 不是死点。
- risk: systemd debug 输出会增加串口量；本轮只用于定位，不作为最终完成路径。

## 收尾结论

- final_result: failed-forward；本轮未完成 full login，但修正了边界判断。
- evidence_summary: debug bootargs 生效；`Hostname set to <ysyx-ubuntu2204>.` 后继续出现 `Successfully forked off '(sd-executor)' as PID 27` 和 PID 28-41 的多个 `(direxec)`，200M progress PC 为 `0x0000003f86c44fde`。因此 profile rerun 的 hostname 后沉默不是最终死点，下一层应追 systemd generator/direxec。
