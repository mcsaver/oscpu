# Dispatch Log

## 基本信息

- `task_id`: 2026-06-15-linux-platform-build-isolation-manual
- `trace_id`: manual:2026-06-15-linux-platform-build-isolation
- `log_policy`: append-only

## 事件

### [2026-06-15 16:20:00 +0800] `analyze-paths` - `PASS`

- `action`: 梳理 Linux Makefile、OpenSBI/Linux/rootfs 脚本、NEMU/NPC helper 和 e2e contract 的路径来源。
- `result`: 确认旧共享输出集中在 `Linux/env/src/linux`、`Linux/env/build`、`Linux/env/images`、`Linux/env/logs` 与 `Linux/build`。

### [2026-06-15 16:45:00 +0800] `implement-platform-isolation` - `PASS`

- `action`: 为 `ARCH=riscv64-<platform>` 增加平台拆分、平台 mk、平台 build/image/log roots、Linux `O=` 和 OpenSBI/image/log 默认路径。
- `result`: NEMU/NPC 默认输出拆分到 `Linux/env/platforms/{nemu,npc}` 与 `Linux/build/riscv64-{nemu,npc}`。

### [2026-06-15 16:58:00 +0800] `fix-opensbi-o-dir` - `PASS`

- `action`: 修复 OpenSBI `O=` 目录父路径不存在时 `readlink -f $(O)` 为空的问题。
- `result`: `build-opensbi.sh` 在调用 OpenSBI Makefile 前执行 `mkdir -p "$BUILD_DIR"`。

### [2026-06-15 17:10:00 +0800] `verify-builds` - `PASS`

- `action`: 运行 NEMU/NPC paths、DTB、OpenSBI、Linux image、kernel config 和源码树干净检查。
- `result`: 全部 PASS；NEMU/NPC kernel 和 OpenSBI 输出互不覆盖。

### [2026-06-15 17:15:00 +0800] `verify-contracts` - `PASS`

- `action`: 运行 e2e profile validate 和 direct rv64-linux contract。
- `result`: `contracts` 与 `rv64-linux` profile validate PASS；direct `e2e_rv64_linux_contract` PASS。

### [2026-06-15 17:20:00 +0800] `persist-memory` - `PASS`

- `action`: 更新 `project-status.md`、`modules/nemu.md`、`modules/npc.md` 与本 task-run。
- `result`: 稳定结论已写入 memory。
