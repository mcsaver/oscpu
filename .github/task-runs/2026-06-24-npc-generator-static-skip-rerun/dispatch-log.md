# Dispatch Log

## 基本信息

- task_id: 2026-06-24-npc-generator-static-skip-rerun
- task_slug: npc-generator-static-skip-rerun
- graph_template: rv64-ubuntu-rootfs-loop

---

### [2026-06-24] static-skip-impl - completed

- action: 新增 libc-free `ysyx-npc-generator-skip`，用 direct syscall 读取 `/etc/ysyx-npc-generator-skip-list`，打印 generator markers，命中 skip 后直接 `_exit(0)`。
- outputs: `bash -n` PASS；`riscv64-linux-gnu-gcc ... -nostdlib -static` PASS，产物为 rv64imac/lp64 soft-float static ELF；`git diff --check` PASS。

### [2026-06-24] npc-generator-static-skip-rerun - completed

- action: 构建独立 static-skip rootfs 并运行 NPC 400M cycles 对照。
- outputs: 静态 readiness PASS，runtime `BEGIN/STATIC_SKIP/SKIP/END=13/13/13/13`，无 `unhandled signal 11` 或 `badaddr=0xda`，`run.rc=2`，未到 login marker。

### [2026-06-24] analyze - completed

- action: 与 shell v2 400M 对照计数。
- outputs: shell v2 为 `BEGIN=11`、`END=10`、`SIGSEGV=5`、`badaddr_0xda=10`；static skip-all 移除该崩溃签名，说明前沿转向动态 shell/glibc exit 或真实 generator body。

### [2026-06-24] record - completed

- action: 写入后处理摘要并同步 memory。
- outputs: `evidence/postprocess-summary.txt`
