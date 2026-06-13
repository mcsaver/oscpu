# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-define-params`
- `task_slug`: `npc-define-params`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-22] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求统一 NPC core 可定制参数。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、project/memory、NPC study。
- `action`: 读取项目规则、RTL workflow、NPC memory 与 study 索引。
- `outputs`: 明确需要中文、先分析、RTL 四段推导、完成后更新 memory/task-runs。
- `evidence`: 已读取并按规则执行。
- `handoff_to`: `audit-params`
- `next_step`: 搜索参数定义与引用。
- `notes`: 任务触及多个 RTL 文件，按跨模块处理。

### [2026-05-22] `audit-params` - `completed`

- `owner_agent`: Codex
- `trigger`: 需要区分全局可调参数与通用 IP 泛型。
- `depends_on`: `recall`
- `inputs`: `rg parameter/localparam`、`define.v`、BPU/cache/IF/pipe/NpcCore 源码。
- `action`: 梳理 reset PC、BPU index、BPU 表规模、RAS 深度、I/D cache line/index/word、cacheable 范围、AXI 地址图。
- `outputs`: 确定通用 SRAM/crossbar/UART 接口泛型继续留在模块参数中。
- `evidence`: 静态搜索确认 `NpcCore/IfStage/BranchPredictor/IfIdPipeReg/IdExPipeReg` 存在分散参数链。
- `handoff_to`: `refactor-defines`
- `next_step`: 落 `define.v` 宏区并替换引用。
- `notes`: 不改协议和状态机。

### [2026-05-22] `refactor-defines` - `completed`

- `owner_agent`: Codex
- `trigger`: 参数治理实现。
- `depends_on`: `audit-params`
- `inputs`: 可调参数清单。
- `action`: 在 `define.v` 增加 `ifndef` 默认宏；移除 BPU/RESET 模块参数链；cache 使用宏别名；`tb_branch_predictor` 改为宏位宽和训练长度。
- `outputs`: RTL 和 testbench 改动。
- `evidence`: `make -C npc/single lint` PASS；首次 testbench 暴露旧 10-bit 测试假设，修正后回归通过。
- `handoff_to`: `verify`
- `next_step`: 全量验证。
- `notes`: `tb_branch_predictor` 失败根因是测试位宽和训练轮数隐含旧 `BPU_BHT_INDEX_W=10`。

### [2026-05-22] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 改动后必须验证。
- `depends_on`: `refactor-defines`
- `inputs`: 改动后源码。
- `action`: 执行 lint、模块 testbench、pipe_test、Verilator build、AM cpu-tests。
- `outputs`: 全部通过。
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single/testbench RESULT_DIR=/tmp/npc-param-define-tests run` 24/24 PASS；`make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-param-define-pipe pipe_test` PASS；`make -C npc/single -j14` PASS；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 38/38 PASS。
- `handoff_to`: `record`
- `next_step`: 写 memory。
- `notes`: 当前本地回归显示 Difftest OFF。

### [2026-05-22] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 完成任务后持久化记录。
- `depends_on`: `verify`
- `inputs`: 改动清单与验证证据。
- `action`: 更新 project status、NPC module memory、decisions 和 task-runs。
- `outputs`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/decisions.md`、本目录记录文件。
- `evidence`: 记录已落盘。
- `handoff_to`: 无
- `next_step`: 向用户汇报结果。
- `notes`: 无
