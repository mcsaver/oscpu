# Dispatch Log

## 基本信息

- `task_id`: `2026-05-19-nemu-bpu`
- `task_slug`: `nemu-bpu`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-19 18:30] `recall-context` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求 NEMU 增加 BPU/RAS
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/nemu.md`
- `action`: 读取仓库规范与 NEMU 模块记忆，检索 `cpu-exec.c`、`inst.c`、Kconfig 和 cache 统计实现。
- `outputs`: 确认 BPU 应接入 `exec_once()` 中 `isa_exec_once()` 之后、`cpu.pc = s->dnpc` 之前。
- `evidence`: `rg` 命中 `exec_once -> isa_exec_once -> cpu.pc`；`inst.c` 中 RV32 branch/JAL/JALR/RVC 控制流均通过 `dnpc` 表达真实目标。
- `handoff_to`: `bpu-unit-red-green`
- `next_step`: 先写单元测试。
- `notes`: 当前工作区已有未提交 cache/RV32 扩展等改动，BPU 需在现有代码上追加，禁止回退。

### [2026-05-19 18:34] `bpu-unit-red-green` - `completed`

- `owner_agent`: Codex
- `trigger`: TDD 要求生产实现前先写失败测试
- `depends_on`: `recall-context`
- `inputs`: BPU API 设计：`init_bpu/bpu_commit/bpu_get_stats`
- `action`: 新增 `nemu/tests/bpu_unit.c`，覆盖 taken branch 学习、RAS call 后 return 命中、RAS 深度溢出。
- `outputs`: `nemu/include/cpu/bpu.h`、`nemu/src/cpu/bpu.c` 和测试配置垫片。
- `evidence`: RED: `fatal error: cpu/bpu.h: No such file or directory`；GREEN: `cc -std=gnu11 -Wall -Werror -I nemu/tests -I nemu/include -o /tmp/bpu_unit nemu/tests/bpu_unit.c nemu/src/cpu/bpu.c && /tmp/bpu_unit` 输出 `bpu_unit PASS`。
- `handoff_to`: `bpu-integration`
- `next_step`: 接入 Kconfig、初始化、提交和统计。
- `notes`: 测试配置使用 `BPU_BTB_ENTRIES=4/BHT=8/RAS=2`，便于覆盖 RAS overflow。

### [2026-05-19 18:39] `bpu-integration` - `completed`

- `owner_agent`: Codex
- `trigger`: BPU 单元模型通过，需要接入 NEMU 正常运行路径
- `depends_on`: `bpu-unit-red-green`
- `inputs`: `nemu/Kconfig`、`cpu-exec.c`、`monitor.c`
- `action`: 添加 `CONFIG_BPU` 和参数；`init_monitor()` 初始化 BPU；`exec_once()` 在真实 `dnpc` 生成后提交预测事件；`statistic()` 输出 BPU counter。
- `outputs`: BPU 已进入 native RISC-V 默认配置。
- `evidence`: `tools/kconfig/build/conf --syncconfig Kconfig` 后 `.config` 与 `autoconf.h` 出现 `CONFIG_BPU=y` 及参数；`make -C nemu -j4` 通过。
- `handoff_to`: `rv32-reference-verify`
- `next_step`: 跑 AM cpu-tests。
- `notes`: 第一次 `ALL=add` 通过但未输出 BPU counter，根因是生成配置尚未同步；同步 Kconfig 后重新构建解决。

### [2026-05-19 18:44] `rv32-reference-verify` - `completed`

- `owner_agent`: Codex
- `trigger`: 功能回归与统计输出验证
- `depends_on`: `bpu-integration`
- `inputs`: `am-kernels/tests/cpu-tests`
- `action`: 运行单项和全量 AM cpu-tests。
- `outputs`: 功能回归通过，BPU counter 可见。
- `evidence`: `make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run` PASS，输出 `bpu branch/target/btb/ras`；`timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run` 输出 35/35 PASS。
- `handoff_to`: `record-memory`
- `next_step`: 更新 memory 和 task-run。
- `notes`: BPU 模型没有改变功能 PC，所有用例仍 HIT GOOD TRAP。

### [2026-05-19 18:45] `record-memory` - `completed`

- `owner_agent`: Codex
- `trigger`: 仓库规范要求完成后更新 memory 与 task-runs
- `depends_on`: `rv32-reference-verify`
- `inputs`: 改动清单与验证证据
- `action`: 追加 project status、NEMU 模块笔记、设计决策和本目录任务报告。
- `outputs`: `.github/memory/project-status.md`、`.github/memory/modules/nemu.md`、`.github/memory/decisions.md`、`.github/task-runs/2026-05-19-nemu-bpu/`
- `evidence`: 本条记录和 task report 已落盘。
- `handoff_to`: 无
- `next_step`: 向用户汇报结果。
- `notes`: 无

### [2026-05-19 18:54] `bpu-kconfig-rehome` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求 BPU 配置不要放在 `Testing and Debugging`，而是在主配置中作为专门模块配置。
- `depends_on`: `bpu-integration`
- `inputs`: `nemu/Kconfig` 中的 BPU 配置块、现有 `src/*/Kconfig` 分模块模式。
- `action`: 新增 `nemu/src/cpu/Kconfig`，把 `CONFIG_BPU` 及 BTB/BHT/RAS/counter/GHR 参数移入 `CPU Performance Models` 独立菜单；主 `nemu/Kconfig` 在顶层 source 该模块，并从 `Testing and Debugging` 删除 BPU 块。
- `outputs`: BPU 配置现在属于 CPU 性能模型配置，不再属于测试调试配置。
- `evidence`: 先用静态检查复现缺少 `nemu/src/cpu/Kconfig` 且 `Testing and Debugging` 内含 `config BPU`；修改后同一检查通过。随后 `tools/kconfig/build/conf --syncconfig Kconfig`、`make -C nemu -j4`、`bpu_unit PASS`、`make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu ALL=add run` PASS 且继续输出 BPU/RAS counter。
- `handoff_to`: 无
- `next_step`: 向用户汇报配置迁移结果。
- `notes`: 本次只调整配置组织，不改变 BPU 运行时行为。
