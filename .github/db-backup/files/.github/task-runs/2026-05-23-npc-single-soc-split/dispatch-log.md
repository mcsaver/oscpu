# Dispatch Log

## 基本信息

- `task_id`: `2026-05-23-npc-single-soc-split`
- `task_slug`: `npc-single-soc-split`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-23 00:00] `copy-integrated-tree` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求新增 `npc/soc` 管理 SoC 接入版本。
- `depends_on`: 无
- `inputs`: 当前 integrated `npc/single`。
- `action`: 用 `rsync` 复制到 `npc/soc/`，排除 `build/`、`perf/results/`、`testbench/build/`。
- `outputs`: 新增 `npc/soc/`。
- `evidence`: `npc/soc/Makefile` 保留 `soc/soc-lint`；`npc/soc/vsrc/core/ysyx_26010035.v` 和 `npc/soc/vsrc/bus/NpcSoCAxiBridge.v` 存在。
- `handoff_to`: `restore-single-abi`
- `next_step`: 恢复 `npc/single` 非 SoC ABI。
- `notes`: 复制发生在恢复 single 之前，避免丢失 SoC 接入产物。

### [2026-05-23 00:00] `restore-single-abi` - `completed`

- `owner_agent`: Codex
- `trigger`: `npc/soc` 已保留 integrated 版本。
- `depends_on`: `copy-integrated-tree`
- `inputs`: `npc/single/Makefile`、`filelist.mk`、`NpcCore.v`、`NpcSimTop.sv`、核级 testbench。
- `action`: 从 `single` 移除 `soc/soc-lint`、ysyxSoC 源列表、SoC warning policy、`SOC_CPU_SRCS`、`ysyx_26010035`、`NpcSoCAxiBridge` 和 `soc-main.cpp`；恢复 `NpcCore` 不导出 `ifu_axi_abort_o`，`NpcSimTop` 继续用 `u_core.ex_any_flush_w`。
- `outputs`: `npc/single` 不再包含 ysyxSoCFull 接入目标。
- `evidence`: `rg` 在 `npc/single` 中找不到 `ysyx_26010035/NpcSoCAxiBridge/soc-lint/ifu_axi_abort_o`。
- `handoff_to`: `verify-both-trees`
- `next_step`: 分别验证 single 与 soc。
- `notes`: `single` 中已有的 NPC 自仿真设备地址图保持不动。

### [2026-05-23 00:00] `verify-both-trees` - `completed`

- `owner_agent`: Codex
- `trigger`: 两个目录拆分完成。
- `depends_on`: `restore-single-abi`
- `inputs`: `npc/single`、`npc/soc`。
- `action`: 运行 lint、SoC lint/build、SoC smoke 和 single NpcCore testbench。
- `outputs`: 验证通过。
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/soc lint` PASS；`make -C npc/soc soc-lint` PASS；`make -C npc/soc soc` PASS；`./npc/soc/build/ysyxSoCFull` 退出码 0；`tb_npc_core_smoke/mcycle/interrupt` PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory。
- `notes`: 无。

### [2026-05-23 00:00] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成。
- `depends_on`: `verify-both-trees`
- `inputs`: 改动摘要和验证证据。
- `action`: 新增 task-run，更新 project-status 与 NPC 模块笔记。
- `outputs`: 记录完成。
- `evidence`: 本目录与 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`。
- `handoff_to`: 无
- `next_step`: 无。
- `notes`: 无。
