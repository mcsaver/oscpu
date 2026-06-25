# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-generator-skip-all-rerun
- task_slug: npc-generator-skip-all-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] generator-skip-impl - completed

- action: 在 generator trace wrapper 中新增默认空 skip list；命中 `all` 或 generator 名称时打印 SKIP 与 END 并返回 0。
- outputs: 默认路径不变；checker 可要求 wrapper 内含 skip list。

### [2026-06-24] npc-generator-skip-all-rerun - completed

- action: 构建独立 skip-all rootfs 并运行 NPC 短周期对照。
- outputs: v1 300M `run.rc=2`，但 wrapper 使用外部 `printf | tr` 导致早期 generator 诊断污染，判为 invalid-control。

### [2026-06-24] generator-skip-impl-v2 - completed

- action: 将 skip-list 匹配改成纯 shell `case`，避免在 generator wrapper 入口 fork 外部命令。
- outputs: `bash -n`/`git diff --check` PASS，静态 checker 可识别 `UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP=all`。

### [2026-06-24] npc-generator-skip-all-v2-300m - completed

- action: 使用 v2 独立 rootfs 运行 300M 对照。
- outputs: 前 5 个 generator 均出现 `BEGIN/SKIP/END`，推进到 `systemd-getty-generator`，但未到 login marker，`run.rc=2`。

### [2026-06-24] npc-generator-skip-all-v2-400m - completed

- action: 复用 v2 rootfs 延长到 400M cycles。
- outputs: 11 个 `BEGIN`、10 个 `SKIP`、10 个 `END`；5 次 `unhandled signal 11` 落在不同 generator 进程的 `libc.so.6`，均为 `badaddr=0xda`；末尾 `0xffffffff802a86b0 -> tty_unthrottle`，`run.rc=2`，无 login marker。

### [2026-06-24] record - completed

- action: 记录 task-run 后处理摘要，并同步 project-status、npc module memory、known issue [96]。
- outputs: `evidence/postprocess-summary.txt`
