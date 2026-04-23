# Dispatch Log

## 基本信息

- `task_id`: `2026-04-22-nemu-kconfig-batch-mode`
- `task_slug`: `nemu-kconfig-batch-mode`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-04-22 14:21] `trace-kconfig-path` - `completed`

- `owner_agent`: `codex`
- `trigger`: `用户要求把 batch mode 提升到 Kconfig`
- `depends_on`: `none`
- `inputs`: `nemu/Kconfig`、`nemu/src/monitor/sdb/sdb.c`、`scripts/config.mk`
- `action`: `梳理 Kconfig 到源码宏的接线方式，确认 batch mode 应被建模为“默认启动行为”，而不是替换命令行 -b`
- `outputs`: `新增 CONFIG_BATCH_MODE 的设计决策`
- `evidence`: `现有 -b 已能按次开启，因此 Kconfig 只需要控制默认值`
- `handoff_to`: `patch-kconfig-default`
- `next_step`: `落 Kconfig 和 sdb 默认值初始化`
- `notes`: `none`

### [2026-04-22 14:24] `patch-kconfig-default` - `completed`

- `owner_agent`: `codex`
- `trigger`: `接线点已明确`
- `depends_on`: `trace-kconfig-path`
- `inputs`: `nemu/Kconfig`、`nemu/src/monitor/sdb/sdb.c`
- `action`: `在 Kconfig 中新增 CONFIG_BATCH_MODE，限制为 !TARGET_AM；在 sdb.c 中用 MUXDEF(CONFIG_BATCH_MODE, true, false) 初始化 is_batch_mode`
- `outputs`: `Kconfig 可配置的默认批处理行为`
- `evidence`: `git diff 显示仅修改 nemu/Kconfig 与 nemu/src/monitor/sdb/sdb.c 两个实现点`
- `handoff_to`: `verify-default-and-cli`
- `next_step`: `验证默认关闭和命令行路径`
- `notes`: `命令行 -b 逻辑保持不变`

### [2026-04-22 14:27] `verify-default-and-cli` - `completed`

- `owner_agent`: `codex`
- `trigger`: `修改后需要先确认默认配置没有被意外改成 always-on`
- `depends_on`: `patch-kconfig-default`
- `inputs`: `默认 .config、构建后的 NEMU`
- `action`: `执行 make -C nemu -j4，检查默认配置下 .config 没有 CONFIG_BATCH_MODE=y，并运行 make -C nemu ISA=riscv32 run ARGS=-b`
- `outputs`: `默认关闭 + 显式开启两条证据`
- `evidence`: `当前 nemu/.config 为 # CONFIG_BATCH_MODE is not set；显式 -b 仍直接 HIT GOOD TRAP`
- `handoff_to`: `verify-kconfig-enabled`
- `next_step`: `临时打开 CONFIG_BATCH_MODE=y 验证自动批处理启动`
- `notes`: `none`

### [2026-04-22 14:30] `verify-kconfig-enabled` - `completed`

- `owner_agent`: `codex`
- `trigger`: `需要证明 Kconfig 入口不是死配置`
- `depends_on`: `verify-default-and-cli`
- `inputs`: `/tmp/nemu.config.batch.test`、`tools/kconfig/build/conf`
- `action`: `备份原 .config，生成临时测试配置追加 CONFIG_BATCH_MODE=y，显式执行 conf --defconfig/--syncconfig 后运行 make -C nemu ISA=riscv32 run ARGS=`
- `outputs`: `Kconfig 开启时的自动批处理证据`
- `evidence`: `临时 .config 和 include/generated/autoconf.h 都出现 CONFIG_BATCH_MODE；不传 -b 的 native run 直接 HIT GOOD TRAP`
- `handoff_to`: `restore-config`
- `next_step`: `恢复原始配置并确认工作区回到默认关闭`
- `notes`: `none`

### [2026-04-22 14:32] `restore-config` - `completed`

- `owner_agent`: `codex`
- `trigger`: `测试结束后不能把临时配置留在工作区`
- `depends_on`: `verify-kconfig-enabled`
- `inputs`: `/tmp/nemu.config.batch.backup`
- `action`: `恢复原 .config，再显式执行一次 syncconfig 与 make -C nemu -j4，最后追加跑 make -C am-kernels/kernels/hello ARCH=riscv32-nemu c mainargs=h 做回归`
- `outputs`: `恢复后的工作区状态与 AM on NEMU 回归结果`
- `evidence`: `当前 nemu/.config 回到 # CONFIG_BATCH_MODE is not set；hello 仍通过 -b 路径 HIT GOOD TRAP`
- `handoff_to`: `record-memory`
- `next_step`: `更新 memory 与 task-run`
- `notes`: `恢复 .config 后若不显式 syncconfig，autoconf.h 可能短时间滞后`

### [2026-04-22 14:33] `record-memory` - `completed`

- `owner_agent`: `codex`
- `trigger`: `按仓库规范完成记录沉淀`
- `depends_on`: `restore-config`
- `inputs`: `验证结果、memory 协议`
- `action`: `更新 project-status、modules/nemu，并写入本次 task-report 与 dispatch-log`
- `outputs`: `长期记忆与单次任务证据链`
- `evidence`: `memory 条目与 task-run 文件均已新增`
- `handoff_to`: `none`
- `next_step`: `向用户交付结果`
- `notes`: `none`
