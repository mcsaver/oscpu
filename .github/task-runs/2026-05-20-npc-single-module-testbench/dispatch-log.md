# Dispatch Log

## 基本信息

- `task_id`: `2026-05-20-npc-single-module-testbench`
- `task_slug`: `npc-single-module-testbench`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-20 11:20] `recall` - `completed`

- `owner_agent`: codex
- `trigger`: 用户要求在 `single` 下建立模块级 testbench 并在 perf 保存结果
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study、Makefile、perf README
- `action`: 读取仓库规则、NPC 模块记忆、study 索引和现有构建/性能目录
- `outputs`: 确认任务需要覆盖 `npc/single/vsrc` 纯 RTL 模块，结果应落入 `npc/single/perf/results/`
- `evidence`: 读取命令输出已确认模块清单、Icarus/Verilator 工具可用
- `handoff_to`: `testbench-design`
- `next_step`: 设计独立 testbench 入口
- `notes`: 工作区已有大量未提交改动，本轮避免回退或重写用户既有变更

### [2026-05-20 11:32] `testbench-design` - `completed`

- `owner_agent`: codex
- `trigger`: 完成 RECALL
- `depends_on`: `recall`
- `inputs`: `vsrc/*.v` 端口、`npc/single/Makefile` 的 `RTL_CORE_SRCS`
- `action`: 选择 Icarus SystemVerilog 自检 testbench；按模块直接实例化 DUT，按 test 独立编译运行；`NpcSimTop.sv` 保持由原 Verilator/NPC 仿真入口覆盖
- `outputs`: `testbench/Makefile`、`common/tb_common.svh`、`common/rv32_encode.svh` 设计
- `evidence`: `iverilog -V`、`verilator --version` 可用
- `handoff_to`: `implement`
- `next_step`: 落盘 testbench
- `notes`: `VVP` 默认强制优先 `/usr/bin/vvp`，避开本机 PATH 中不完整 oss-cad-suite vvp

### [2026-05-20 11:43] `implement` - `completed`

- `owner_agent`: codex
- `trigger`: testbench 设计确定
- `depends_on`: `testbench-design`
- `inputs`: RTL 模块接口与局部协议
- `action`: 新增 21 个 testbench 入口，覆盖组合单元、译码、LSU、流水线寄存器、控制面、divider、BPU、I/D cache、IF stage 和 NpcCore fetch smoke
- `outputs`: `npc/single/testbench/`
- `evidence`: 文件已创建并纳入 `make -C npc/single/testbench run`
- `handoff_to`: `verify`
- `next_step`: 运行模块级验证
- `notes`: 本轮只新增验证代码，不修改 RTL

### [2026-05-20 11:42] `verify` - `completed`

- `owner_agent`: codex
- `trigger`: testbench 已落盘
- `depends_on`: `implement`
- `inputs`: `npc/single/testbench`
- `action`: 运行模块级 testbench 与原有 Verilator lint
- `outputs`: `npc/single/perf/results/20260520-114215/module-testbench/summary.txt`
- `evidence`: `make -C npc/single/testbench run` 21/21 PASS；`make -C npc/single lint` PASS
- `handoff_to`: `record`
- `next_step`: 更新 memory
- `notes`: 中间曾修正 testbench Makefile shell 转义、Icarus vvp 路径、时钟宏和个别测试时序假设

### [2026-05-20 11:45] `record` - `completed`

- `owner_agent`: codex
- `trigger`: 验证通过
- `depends_on`: `verify`
- `inputs`: summary 与 lint 结果
- `action`: 写入 task-run 报告与长期 memory
- `outputs`: `.github/task-runs/2026-05-20-npc-single-module-testbench/`、memory 更新
- `evidence`: 本目录文件与 memory 条目
- `handoff_to`: 无
- `next_step`: 交付用户
- `notes`: 最终可复跑命令为 `make -C npc/single/testbench run`
