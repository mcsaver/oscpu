# Dispatch Log

## 基本信息

- `task_id`: `2026-05-21-npc-bpu-local-history`
- `task_slug`: `npc-bpu-local-history`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-21 21:30] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户提供 CoreMark/NPC 统计并要求继续优化核心。
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study README。
- `action`: 读取项目规则、NPC 历史状态和 BPU/DCache 近几轮记录。
- `outputs`: 确认当前优先方向应由用户最新统计驱动。
- `evidence`: 记录显示 8KB DCache direct-mapped 无收益，上一轮已新增 top miss PC 画像。
- `handoff_to`: `map-hot-pc`
- `next_step`: 反查 miss PC。
- `notes`: 当前 WSL 可用，后续可以直接跑验证。

### [2026-05-21 21:36] `map-hot-pc` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户日志中 top branch miss PCs。
- `depends_on`: `recall`
- `inputs`: `coremark-riscv32-npc.txt` 与用户 PC 列表。
- `action`: 用反汇编上下文映射 `0x80000c56/0x80000b8e/0x80000c02/0x80000c4a/0x80000bd6/0x80000726/0x800007a4/0x800007bc`。
- `outputs`: miss 主要集中在 `core_state_transition` 字符分类和链表遍历/归并。
- `evidence`: 反汇编上下文显示这些 PC 均为条件分支。
- `handoff_to`: `rtl-derive`
- `next_step`: 选择 BPU local-history 方案。
- `notes`: JALR/RAS 已接近满分，DCache 容量方向证据不足。

### [2026-05-21 21:42] `rtl-derive` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要修改 RTL。
- `depends_on`: `map-hot-pc`
- `inputs`: `BranchPredictor.v` 当前 gshare/BTB/RAS 结构。
- `action`: 按 RTL 四段式推导需求、协议、状态机、不变量和数据通路。
- `outputs`: 选择“local strong 才覆盖 gshare”的低风险方案。
- `evidence`: `task-report.md` 中 “RTL 推导摘要”。
- `handoff_to`: `implement-local-history`
- `next_step`: 修改 RTL 与单测。
- `notes`: 不改变 BPU 外部端口和流水寄存器 payload。

### [2026-05-21 21:50] `implement-local-history` - `completed`

- `owner_agent`: `codex`
- `trigger`: RTL 方案确定。
- `depends_on`: `rtl-derive`
- `inputs`: `BranchPredictor.v`、`tb_branch_predictor.sv`、`NpcCore.v`、`cpu-exec.cpp`。
- `action`: 新增 local history/PHT，增加交替模式单测，更新旧注释与统计文案。
- `outputs`: 4 个源码/测试文件修改。
- `evidence`: `git diff`。
- `handoff_to`: `verify`
- `next_step`: 跑 testbench/lint/build/benchmark。
- `notes`: 统计字段内部命名未大改，输出文案已避免继续称为纯 BHT。

### [2026-05-21 22:00] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: 修改完成。
- `depends_on`: `implement-local-history`
- `inputs`: 改动后的 RTL/C++。
- `action`: 运行模块 testbench、Verilator lint/build、CoreMark 长测、cpu-tests。
- `outputs`: 全部验证通过，CoreMark 指标改善。
- `evidence`: `make -C npc/single/testbench RESULT_DIR=/tmp/npc-bpu-local-tests run` 21/21 PASS；`make -C npc/single lint` PASS；`make -C npc/single -j14` PASS；CoreMark GOOD TRAP；cpu-tests 38/38 PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory 与 task-runs。
- `notes`: 首次 cpu-tests 未传 `AM_HOME` 是环境变量问题，补上后通过。

### [2026-05-21 22:10] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 收尾。
- `depends_on`: `verify`
- `inputs`: 本轮结论和验证数据。
- `action`: 更新 project status、NPC module memory 和本 task-run。
- `outputs`: 记录落盘。
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、本目录。
- `handoff_to`: none
- `next_step`: 用户可复跑 CoreMark 或继续做 DCache 2-way/victim/burst。
- `notes`: 本轮硬件 cycles 改善约 194 万周期，host 仿真频率因表项增加略降。

### [2026-05-21 22:35] `weak-taken-init` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户给出 local-history 后的复跑截图，并要求“把 bpu 开局改成弱跳转”。
- `depends_on`: `verify`
- `inputs`: `BranchPredictor.v` reset 逻辑、`tb_branch_predictor.sv` BPU 单测、用户 CoreMark 截图。
- `action`: 将 gshare BHT 与 local PHT reset counter 从 weak not-taken 改成 weak taken，保留 valid 清零与 cold BTFNT 语义；单测补 reset counter 检查。
- `outputs`: `BranchPredictor.v`、`tb_branch_predictor.sv`、memory 和 task-run 更新。
- `evidence`: 模块 testbench 21/21 PASS；lint PASS；build PASS；CoreMark GOOD TRAP，`cycles=390482073`、branch miss `2458726`；cpu-tests 38/38 PASS。
- `handoff_to`: none
- `next_step`: 若继续追 CoreMark 分数，弱跳转初值应作为可 A/B 的启动偏置；更大收益仍在 DCache 2-way/victim/burst 或更精细 BPU chooser。
- `notes`: valid 仍清零，所以 cold forward branch 仍按 BTFNT not-taken；弱跳转只影响 entry 被训练为 valid 后的弱置信方向。
