# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-vsrc-layout`
- `task_slug`: `npc-vsrc-layout`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-22 18:00] `recall` - `completed`

- `owner_agent`: codex
- `trigger`: 用户要求整理 `npc/single/vsrc` 源码目录。
- `depends_on`: 无。
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`、NPC study README、相关 instructions。
- `action`: 读取仓库规则、NPC 记忆和本地学习资料，确认跨文件任务需要先查依赖、改后验证并更新 memory/task-runs。
- `outputs`: 确认本轮是源码组织重排，不改 RTL 行为。
- `evidence`: 已读文件内容和后续计划。
- `handoff_to`: `map-layout`
- `next_step`: 扫描 vsrc 文件、构建入口和实例化链。
- `notes`: 工作树已有大量未提交改动，本轮不回退用户已有修改。

### [2026-05-22 18:01] `map-layout` - `completed`

- `owner_agent`: codex
- `trigger`: 需要决定商业式目录分层。
- `depends_on`: `recall`
- `inputs`: `rg --files npc/single/vsrc`、`npc/single/Makefile`、`npc/single/testbench/Makefile`、`NpcCore/NpcSimTop` 实例化链。
- `action`: 按架构职责映射目录：`include/core/frontend/decode/execute/memory/cache/bus/common/pipeline/writeback/sim`。
- `outputs`: 文件移动映射和共享 filelist 方案。
- `evidence`: `NpcCore` 实例化 IF/decode/execute/memory/cache/writeback/control；`NpcSimTop` 实例化 core、bus、DPI slave。
- `handoff_to`: `move-files`
- `next_step`: 创建目录并移动文件。
- `notes`: `sim/` 明确隔离 DPI-C 仿真壳，避免混入 STA 入口。

### [2026-05-22 18:02] `move-files` - `completed`

- `owner_agent`: codex
- `trigger`: 执行目录重排。
- `depends_on`: `map-layout`
- `inputs`: 平铺 `vsrc/*.v` / `vsrc/*.sv`。
- `action`: 创建功能目录并将源文件原样移动到对应目录。
- `outputs`: 新的 `vsrc` 树。
- `evidence`: `find npc/single/vsrc -maxdepth 2 -type f | sort` 列出所有新路径，根目录仅保留 `filelist.mk`。
- `handoff_to`: `update-build`
- `next_step`: 更新 Makefile/testbench 路径。
- `notes`: 文件内容保持原样，保留已有未提交修改。

### [2026-05-22 18:03] `update-build` - `completed`

- `owner_agent`: codex
- `trigger`: 构建入口仍引用旧平铺路径。
- `depends_on`: `move-files`
- `inputs`: `npc/single/Makefile`、`npc/single/testbench/Makefile`、README、NPC agent 文档。
- `action`: 新增 `vsrc/filelist.mk` 集中维护 `RTL_*` 路径变量和源文件集合；主 Makefile 与 testbench include 该清单并补 `-I$(RTL_INCLUDE_DIR)`；文档目录树同步更新。
- `outputs`: 共享 filelist、更新后的构建入口与文档。
- `evidence`: `make -C npc/single -n lint` 和 `make -C npc/single/testbench -n run` 展开到新目录路径；旧平铺路径搜索无命中。
- `handoff_to`: `verify`
- `next_step`: 运行真实构建和回归。
- `notes`: 后续新增 RTL 时只需要更新 `filelist.mk`。

### [2026-05-22 18:04] `verify` - `completed`

- `owner_agent`: codex
- `trigger`: 需要证明路径重排不破坏编译与运行。
- `depends_on`: `update-build`
- `inputs`: 新目录、新 filelist、更新后的 Makefile/testbench。
- `action`: 运行 lint、强制构建、模块自检、流水微基准和 cpu-tests。
- `outputs`: 全部验证通过。
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single -B -j14` PASS；`make -C npc/single/testbench RESULT_DIR=/tmp/npc-vsrc-layout-tests run` 22/22 PASS；`make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-vsrc-layout-pipe pipe_test` PASS；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 38/38 PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory 和决策记录。
- `notes`: `make -C npc/single -j14` 曾因二进制较新 no-op，因此额外使用 `-B` 强制重建。

### [2026-05-22 18:06] `record` - `completed`

- `owner_agent`: codex
- `trigger`: 按仓库协议沉淀稳定结论。
- `depends_on`: `verify`
- `inputs`: 改动清单与验证结果。
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/decisions.md`，并写入本 task-run。
- `outputs`: 长期记忆与单次任务记录。
- `evidence`: 本目录 `task-report.md` 与 `dispatch-log.md`。
- `handoff_to`: 无。
- `next_step`: 交付用户。
- `notes`: 无。
