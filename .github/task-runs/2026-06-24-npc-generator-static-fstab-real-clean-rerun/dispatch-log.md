# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-generator-static-fstab-real-clean-rerun
- task_slug: npc-generator-static-fstab-real-clean-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] clean-real-storage - completed

- action: 根据污染版证据，将 real generator 从 `/lib/systemd/system-generators/*.ysyx-real` 迁到 `/usr/local/lib/ysyx-npc-system-generators/{lib,usr-lib}/`，避免 systemd 将 real binary 当作额外 generator 直接执行。
- outputs: `bash -n` PASS；静态 RISC-V ELF 编译 PASS。

### [2026-06-24] npc-static-fstab-real-clean-rerun - completed

- action: 构建只放开 `systemd-fstab-generator` 的 clean static-wait rootfs，并运行 NPC 500M cycles。
- outputs: `run.rc=2`；rootfs checker PASS；real path 为 `/usr/local/lib/ysyx-npc-system-generators/lib/systemd-fstab-generator`；扫描目录 stale `.ysyx-real` absent；`__NPC_GENERATOR_REAL_STATUS__:systemd-fstab-generator pid=34 raw=0 exit=0`；无 duplicate mount、无 `.ysyx-real failed`、无 segv/badaddr/panic/SIGILL/longjmp；未到 login marker。

### [2026-06-24] analyze - completed

- action: 后处理 clean console 与 rootfs debugfs stat。
- outputs: `evidence/postprocess-summary.txt`；下一步应定位 generator 阶段之后的 systemd/userspace 停留，或继续 all-except-one 矩阵逐个恢复 generator body。
