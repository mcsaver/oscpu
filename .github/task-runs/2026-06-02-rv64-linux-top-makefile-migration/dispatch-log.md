# Dispatch Log

- 读取仓库 AGENTS/copilot/memory/instructions，确认用户要求：先修 bug、禁止为了跑通绕过问题；Linux/Ubuntu 资源迁移到根目录 `Linux/`，`npc/rv64` 保持 core RTL/仿真边界。
- 审计旧路径：`npc/rv64/env`、`platform`、`scripts`、`patches`、`regression`、Linux 专用 `configs`、`tools` 中的 boot payload、DTB/OpenSBI smoke、SRET/Sv39/RAS/FP focused gates。
- 迁移 Linux bring-up 资源到 `Linux/`，并更新脚本中的根路径变量为 `LINUX_HOME`/`YSYX_LINUX_*`。
- 新建 `Linux/Makefile`，统一 `ARCH`、`BOOT`、artifact、QEMU、OpenSBI、initramfs、rootfs、smoke 和 tools 入口。
- 调整 `Linux/tools/Makefile`，保留 focused tool tests 并新增 boot tool/DTB/OpenSBI smoke 目标。
- 清理 `npc/rv64/Makefile` 中 Linux/OpenSBI/Ubuntu 管理目标，避免 core 模块继续承担 Linux 资源管理职责。
- 更新 `Linux/README.md`、`Linux/env/README.md`、`Linux/platform/*`、`.gitignore` 和相关 `.github` agent/instructions。
- 运行 dry-run 与 focused 验证，确认 `make -C Linux ARCH=riscv64-npc run` 不再被 shell gate 占用，shell/probe 需要显式 `BOOT=`。
- 更新 memory 与本 task-run，记录新入口、验证证据和仍未闭合的 rootfs/virtio/display 边界。
