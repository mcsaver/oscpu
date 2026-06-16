# Dispatch Log

## 基本信息

- `task_id`: `2026-05-25-npc-single-mul-pipeline`
- `task_slug`: `npc-single-mul-pipeline`
- `graph_template`: `npc-sim-regression`
- `log_policy`: `append-only`

---

### [2026-05-25 19:00] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求 single 核心乘法器改为 5 级流水线。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、NPC study。
- `action`: 读取仓库规则，定位 RV32M 乘法实现和 EX 等待控制链。
- `outputs`: 确认组合乘法位于 `NpcCore.rv32m_mul_result()`，除法已有 `req/rsp + ex_wait` 可复用边界。
- `evidence`: `rg` 与 `nl` 检查 `NpcCore.v`、`PipelineControl.v`、`Rv32Divider.v`。
- `handoff_to`: `implement`
- `next_step`: 新增 5 级流水乘法器并接入 core。
- `notes`: 按 RTL 工作流先完成需求、协议、状态机、不变量、数据通路推导。

### [2026-05-25 19:08] `implement` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 推导完成。
- `depends_on`: `recall`
- `inputs`: `NpcCore` 乘除法路径、`Rv32Divider` 协议。
- `action`: 新增 `Rv32Multiplier.v`；删除组合乘法函数；加入 `mul_req_issued_q`；更新 filelist 和模块 testbench。
- `outputs`: single 乘法指令通过 EX `req/rsp` 等待 5 级流水响应后再进入 WBU。
- `evidence`: 新增 `tb_multiplier`；`tb_npc_core_smoke` 改为 `mul x10,x1,x2` 并检查写回 60。
- `handoff_to`: `verify`
- `next_step`: 运行 lint、模块 testbench、pipe test、AM 回归。
- `notes`: `npc/soc` 未同步修改，符合本轮 single 范围。

### [2026-05-25 19:14] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 接入完成。
- `depends_on`: `implement`
- `inputs`: 修改后的 `npc/single`。
- `action`: 运行静态和动态回归。
- `outputs`: 所有验证通过。
- `evidence`: `make -C npc/single lint` PASS；`make -C npc/single/testbench ... run` 27/27 PASS；`make -C npc/single/testbench ... pipe_test` PASS；`make -C npc/single -j4` PASS；`mul-longlong`、`matrix-mul`、`div` on `riscv32-npc` PASS；`git diff --check` PASS。
- `handoff_to`: `record`
- `next_step`: 更新 memory。
- `notes`: 当前 Difftest 编译配置为 OFF，因此 AM 回归以 GOOD TRAP/PASS 为证据。

### [2026-05-25 19:20] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成。
- `depends_on`: `verify`
- `inputs`: 变更摘要与验证证据。
- `action`: 写入 task report、dispatch log、project status 和 NPC 模块笔记。
- `outputs`: 本目录记录与 memory 条目。
- `evidence`: `.github/task-runs/2026-05-25-npc-single-mul-pipeline/`
- `handoff_to`: 无
- `next_step`: 无
- `notes`: 无
