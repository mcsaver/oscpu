# Dispatch Log

## 基本信息

- `task_id`: `2026-05-23-npc-soc-device-map`
- `task_slug`: `npc-soc-device-map`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-23 10:00] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求按设备地址表预留接口
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study、现有 RTL
- `action`: 读取工程约束、NPC 模块状态、RTL 生成规范和现有 `NpcCore/NpcSimTop/NpcAxiBus`。
- `outputs`: 确认设备应预留在 `NpcSimTop` slave 侧，`NpcCore` ABI 不改。
- `evidence`: 本轮只读调研输出
- `handoff_to`: `derive-rtl`
- `next_step`: 推导地址图扩展方案
- `notes`: 发现当前工作区已有 NEMU/AM 未提交改动，本轮只追加 NPC 相关改动。

### [2026-05-23 10:10] `derive-rtl` - `completed`

- `owner_agent`: Codex
- `trigger`: 准备修改 RTL
- `depends_on`: `recall`
- `inputs`: 用户地址表、现有 AXI-like 协议、`AxiDefaultSlave/AxiDpiSlave`
- `action`: 按需求、协议规则、状态机、不变量、数据通路约束完成 RTL 推导。
- `outputs`: 决定新增地址宏、扩展 `NpcSimTop` slave index、未实现窗口接 `AxiDefaultSlave`。
- `evidence`: `task-report.md` 的 RTL 推导摘要
- `handoff_to`: `implement-map`
- `next_step`: 落盘 RTL
- `notes`: legacy DPI MMIO 明确标注为当前仿真兼容例外。

### [2026-05-23 10:20] `implement-map` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 推导完成
- `depends_on`: `derive-rtl`
- `inputs`: `npc/single/vsrc/include/define.v`、`npc/single/vsrc/sim/NpcSimTop.sv`
- `action`: 新增 ysyxSoC 地址宏；将 `NpcSimTop` slave 数扩到 15；PSRAM 接 DPI，CLINT/UART 接真实模块，未实现窗口用 generate 接错误 slave。
- `outputs`: RTL 修改完成
- `evidence`: `git diff --check -- npc/single/vsrc/include/define.v npc/single/vsrc/sim/NpcSimTop.sv` PASS
- `handoff_to`: `verify`
- `next_step`: lint/build/smoke
- `notes`: 初版 helper 触发 Verilator 宽度告警，已通过 4-bit index 和 int default 参数修正。

### [2026-05-23 10:30] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 修改完成
- `depends_on`: `implement-map`
- `inputs`: 修改后 RTL
- `action`: 运行 lint、Verilator build、`add` 镜像 smoke。
- `outputs`: 验证通过
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single -j14` PASS；`./npc/single/build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-diff --no-progress -m 0` HIT GOOD TRAP，`CLINT mtime = 1355 (match=yes)`
- `handoff_to`: `record`
- `next_step`: 更新 memory
- `notes`: 构建中仍有既有 capstone 路径 `snprintf` 编译告警，不属于本轮 RTL 改动。

### [2026-05-23 10:40] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成
- `depends_on`: `verify`
- `inputs`: 改动和验证结果
- `action`: 写入 task-run、更新项目状态和 NPC 模块记忆。
- `outputs`: 记录完成
- `evidence`: `.github/task-runs/2026-05-23-npc-soc-device-map/`
- `handoff_to`: 无
- `next_step`: 等待后续设备本体实现任务
- `notes`: 后续严格 ysyxSoC 地址迁移需要处理 legacy MMIO 与 SDRAM 低地址重叠。
