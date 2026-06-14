# Dispatch Log

## 基本信息

- `task_id`: `2026-05-20-npc-difftest-config-switch`
- `task_slug`: `npc-difftest-config-switch`
- `graph_template`: `regression-debug-loop`
- `log_policy`: `append-only`

---

### [2026-05-20 14:40] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求将 difftest 做成可关闭开关。
- `depends_on`: 无。
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study、源码检索。
- `action`: 确认现状为运行时 `--diff`，无 Kconfig 编译期开关。
- `outputs`: 决定采用“编译期能力 + 运行时启用”模型。
- `evidence`: `npc/single/Kconfig` 无 diff 项；`monitor.c` 解析 `--diff`；`Makefile` 无条件链接 `-ldl`。
- `handoff_to`: `implement`
- `next_step`: 修改配置链和 host 入口。
- `notes`: 工作区已有用户/历史改动，避免回退无关文件。

### [2026-05-20 14:42] `implement` - `completed`

- `owner_agent`: `codex`
- `trigger`: `recall` 完成。
- `depends_on`: `recall`
- `inputs`: Kconfig、Makefile、difftest header、monitor parser、cpu exec、README。
- `action`: 新增 `CONFIG_NPC_DIFFTEST`，关闭时过滤 `difftest.cpp`/`-ldl`，给关闭路径加 stub 和 CLI 提示，并用 `#if` 去掉提交热路径分支。
- `outputs`: 代码和文档补丁。
- `evidence`: 文件 diff。
- `handoff_to`: `verify-off`
- `next_step`: 验证关闭路径。
- `notes`: `default_defconfig` 显式打开，`perf_defconfig` 显式关闭。

### [2026-05-20 14:45] `verify-off` - `completed`

- `owner_agent`: `codex`
- `trigger`: 关闭路径补丁完成。
- `depends_on`: `implement`
- `inputs`: 进入任务前的本地 `.config`。
- `action`: 强制重建，检查 help，裸跑 `cpu-tests add`。
- `outputs`: 关闭路径可用。
- `evidence`: `make -C npc/single -B -j4` PASS；`./npc/single/build/NpcSimTop --help` 显示 `--diff` unavailable；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='-m 0'` PASS。
- `handoff_to`: `verify-on`
- `next_step`: 临时打开配置验证原 difftest 用法。
- `notes`: 关闭路径构建命令中没有 `difftest.cpp` 和 `-ldl`。

### [2026-05-20 14:48] `verify-on` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要确认 `--diff=default` 未回归。
- `depends_on`: `verify-off`
- `inputs`: 临时 `default_defconfig`。
- `action`: 打开配置强制重建，检查 help，运行最小 difftest 回归。
- `outputs`: 打开路径可用。
- `evidence`: `make -C npc/single -B -j4` PASS；`--help` 显示 `--diff` available；`make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'` PASS。
- `handoff_to`: `record`
- `next_step`: 恢复本地配置并记录。
- `notes`: 首次打开路径暴露 `disasm.c` 异类型函数指针链式清零错误，已修复后复验通过。

### [2026-05-20 14:52] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 验证完成。
- `depends_on`: `verify-on`
- `inputs`: 验证证据、改动清单。
- `action`: 恢复本地配置并重建关闭路径，更新 memory 和 task-runs。
- `outputs`: 本地最终停在关闭 difftest 的性能配置。
- `evidence`: 恢复后 `make -C npc/single -B -j4` PASS；`make -C npc/single lint` PASS。
- `handoff_to`: 无。
- `next_step`: 向用户汇报。
- `notes`: 无。
