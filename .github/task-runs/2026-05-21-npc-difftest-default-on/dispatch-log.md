# Dispatch Log

## 基本信息

- `task_id`: `2026-05-21-npc-difftest-default-on`
- `task_slug`: `npc-difftest-default-on`
- `graph_template`: `regression-debug-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-21 19:31] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求“开启 difftest 时逐条和 NEMU 对比”
- `depends_on`: 无
- `inputs`: `difftest.md`、`npc.md`、`utils.c`、`monitor.c`、`cpu-exec.cpp`、`difftest.cpp`
- `action`: 梳理 difftest 编译期开关、运行时开关和提交热路径。
- `outputs`: 根因确认：旧行为下 `CONFIG_NPC_DIFFTEST=y` 只编译能力，默认运行不启用 reference。
- `evidence`: `npc_simconfig_init()` 未设置 `difftest=true`；`--diff` 才设置 `config->difftest=true`。
- `handoff_to`: `implement`
- `next_step`: 修改默认初始化和 CLI。
- `notes`: 保留 `perf_defconfig` 的编译期关闭路径。

### [2026-05-21 19:31] `implement` - `completed`

- `owner_agent`: Codex
- `trigger`: recall 结论
- `depends_on`: `recall`
- `inputs`: `utils.c`、`monitor.c`、`Kconfig`、`README.md`
- `action`: 默认设置 `cfg->difftest=CONFIG_NPC_DIFFTEST`；新增 `--no-diff`；welcome 增加 `Difftest: ON/OFF`；更新 help 与文档。
- `outputs`: 验证构建默认逐条 diff，裸跑显式关闭，welcome 能直观看到 difftest 状态。
- `evidence`: 工作区补丁。
- `handoff_to`: `verify`
- `next_step`: 重建并运行 smoke。
- `notes`: `--diff=default|path` 改为显式指定 reference 的入口。

### [2026-05-21 19:31] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: implement 完成
- `depends_on`: `implement`
- `inputs`: `NpcSimTop`、`add-riscv32-npc.bin`
- `action`: 构建并分别运行默认 diff 与 `--no-diff`。
- `outputs`: 两条路径均 GOOD TRAP。
- `evidence`: `make -C npc/single -j4` PASS；`NpcSimTop --help` 显示 `--no-diff`；默认运行打印 `[npc-diff] reference enabled...` 与 `Difftest: ON`；`--no-diff` 运行不打印 reference enabled 且显示 `Difftest: OFF`。
- `handoff_to`: `record`
- `next_step`: 写入长期记忆。
- `notes`: 默认 diff 路径使用 `/home/lyg/PA/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so`。

### [2026-05-21 19:31] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: verify 完成
- `depends_on`: `verify`
- `inputs`: 验证结果与改动清单
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/difftest.md` 与本 task-run。
- `outputs`: 长期记忆同步完成。
- `evidence`: 文件已更新。
- `handoff_to`: 无
- `next_step`: 结束任务。
- `notes`: 无
