# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-generator-static-all-real-clean-rerun
- task_slug: npc-generator-static-all-real-clean-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] all-real-runner - completed

- action: 新增 all-real static-wait runner；skip list 使用不会命中的 `__no_such_generator__`，因此所有 generator 都会走真实 body，并由静态父进程等待/记录状态。
- outputs: runner 已创建，待预检。

### [2026-06-24] npc-static-all-real-clean-rerun - pending

- action: 构建 clean all-real static-wait rootfs，并运行 NPC 1B cycles。
- outputs: rootfs readiness PASS；真实 NPC 到 1B cycles 上限退出，`run.rc=2`，console/npc/run log 已归档到 evidence。

### [2026-06-24] analyze - completed

- action: 后处理 console，统计 generator marker、异常 marker、systemd unit 进度和终态 PC。
- outputs: `BEGIN=13`、`REAL_BEGIN=13`、`REAL_STATUS=13`、`END=13`，所有真实 generator `exit=0`；`STATIC_SKIP=0`、`SKIP=0`；无 segv/badaddr/panic/SIGILL/longjmp/duplicate fstab；未到 `__NPC_LOGIN_CHECK_DONE__ rc=0`。系统已推进到 generator 后的 unit 启动，最后日志停在 Kernel Configuration File System condition skipped 后，1B cycles 上限 abort。

### [2026-06-24] record - completed

- action: 更新本 task-run 报告、补充 postprocess summary，并同步 project-status、NPC module memory 与 known issue [96]。
- outputs: memory/task-run 记录 all-real generator clean 结论；完整 login gate 仍保持 open。
