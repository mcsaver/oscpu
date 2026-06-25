# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-generator-trace-rerun
- task_slug: npc-generator-trace-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] generator-trace-impl - completed

- action: 新增默认关闭的 `UBUNTU_ROOTFS_NPC_GENERATOR_TRACE`，包装 systemd generators 并在 console 打印 begin/end marker。
- outputs: `bash -n` 通过；checker 可要求 `systemd-fstab-generator` wrapper 与 `.ysyx-real`。

### [2026-06-24] npc-generator-trace-rerun - completed

- action: 构建独立 generator-trace rootfs 并短周期运行 NPC。
- outputs: `run.rc=2`；rootfs 静态检查通过；默认 full 镜像无 generator wrapper 残留；guest 到达 systemd generator BEGIN 阶段但未到 login marker。

### [2026-06-24] analyze - completed

- action: 后处理 console/run log，统计 generator begin/end、错误信号和末尾 PC。
- outputs: 5 个 generator BEGIN、0 个 END；末尾 PC `0xffffffff8040fdb6 -> mas_next_slot (maple_tree.c:?)`；`SIGILL`、`longjmp`、`panic`、getty/login、login marker 均为 0。
