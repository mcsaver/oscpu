# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-clint-mtime-stat`
- `task_slug`: `npc-clint-mtime-stat`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-22 19:35] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求把 CLINT `mtime` 引出到仿真统计并和 DPIC cycles 比较。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`、NPC study 笔记。
- `action`: 读取项目规则、NPC 记忆和 mtime/machine timer 相关 study 资料。
- `outputs`: 明确 `mtime` 是平台 MMIO timer，统计增强不能改变 CLINT/core 协议。
- `evidence`: 规则与笔记已读。
- `handoff_to`: `inspect`
- `next_step`: 搜索 CLINT 实例、host cycles 和 statistics 输出。
- `notes`: 无

### [2026-05-22 19:38] `inspect` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要确定层次化引用路径和 host 统计落点。
- `depends_on`: `recall`
- `inputs`: `npc/single/vsrc/bus/AxiLiteClint.v`、`npc/single/vsrc/sim/NpcSimTop.sv`、`npc/single/csrc/cpu/cpu-exec.cpp`、`npc/single/csrc/include/utils.h`
- `action`: 使用 `rg/sed` 查看 `mtime_q`、`u_clint_axi`、`NpcStats::cycles` 和 report 输出。
- `outputs`: 选定 `u_clint_axi.mtime_q -> debug_clint_mtime_o -> NpcStats::clint_mtime -> report_statistics`。
- `evidence`: 静态检查确认实例名和寄存器名。
- `handoff_to`: `implement`
- `next_step`: 修改仿真顶层和 host 统计结构。
- `notes`: 既有 cache/BPU 统计也采用仿真层次化观察，不进入 core ABI。

### [2026-05-22 19:41] `implement` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要落盘实现。
- `depends_on`: `inspect`
- `inputs`: 既有仿真统计和执行循环。
- `action`: `NpcSimTop` 新增 `debug_clint_mtime_o` 并通过 `u_clint_axi.mtime_q` 驱动；`NpcStats` 新增 `clint_mtime`；`step_cycle()` 在 posedge 后采样；统计输出和 `info s` 增加 mtime。
- `outputs`: 代码改动完成。
- `evidence`: `git diff` 和源码检查。
- `handoff_to`: `verify`
- `next_step`: lint/build/运行测试。
- `notes`: 未改变 AXI-Lite CLINT 行为。

### [2026-05-22 19:45] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要验证层次化引用和统计同值。
- `depends_on`: `implement`
- `inputs`: 修改后的 RTL/C++。
- `action`: 运行 lint、Verilator build、单镜像、CLINT testbench、模块级全量 testbench、cpu-tests。
- `outputs`: 全部通过。
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single -j14` PASS；`./npc/single/build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-diff --no-progress` GOOD TRAP，`CLINT mtime = 1355 (mtime-cycles=+0, match=yes)`；`make -C npc/single/testbench TESTS=tb_axi_lite_clint RESULT_DIR=/tmp/npc-mtime-stat-test run` PASS；`make -C npc/single/testbench RESULT_DIR=/tmp/npc-mtime-stat-tests run` 25/25 PASS；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 38/38 PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory。
- `notes`: 本地 cpu-tests 显示 Difftest OFF。

### [2026-05-22 19:50] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 项目规则要求完成后更新 memory 与 task-runs。
- `depends_on`: `verify`
- `inputs`: 改动清单与验证结果。
- `action`: 写入 task report、dispatch log，并更新项目状态与 NPC 模块记忆。
- `outputs`: 记录完成。
- `evidence`: `.github/task-runs/2026-05-22-npc-clint-mtime-stat/`
- `handoff_to`: 无
- `next_step`: 无
- `notes`: 无
