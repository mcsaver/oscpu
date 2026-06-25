# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-generator-static-fstab-real-rerun
- task_slug: npc-generator-static-fstab-real-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] static-wait-impl - completed

- action: 扩展 `ysyx-npc-generator-skip`，在 `/etc/ysyx-npc-generator-real-mode=wait` 时由静态父进程 `clone` 子进程、`execve` 真实 generator、`wait4` 并打印 raw/exit/signal。
- outputs: `bash -n` PASS；静态 RISC-V ELF 编译 PASS；`git diff --check` PASS。

### [2026-06-24] npc-static-fstab-real-rerun - completed

- action: 构建只放开 `systemd-fstab-generator` 的 static-wait rootfs，并运行 NPC 500M cycles。
- outputs: `run.rc=2`；`__NPC_GENERATOR_REAL_STATUS__:systemd-fstab-generator pid=40 raw=0 exit=0`；无 segv/badaddr/panic/SIGILL/longjmp；随后 systemd 又直接执行 `/lib/systemd/system-generators/systemd-fstab-generator.ysyx-real` 并报 duplicate mount / exit status 1。

### [2026-06-24] analyze - completed

- action: 后处理 console，确认 `.ysyx-real` 放在扫描目录是诊断污染。
- outputs: `evidence/postprocess-summary.txt`；后续修复为 `/usr/local/lib/ysyx-npc-system-generators/{lib,usr-lib}/` 非扫描目录。
