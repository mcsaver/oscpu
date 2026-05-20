# Dispatch Log

## 基本信息

- `task_id`: `2026-05-20-npc-asic-timing-rv32m-divider`
- `task_slug`: `npc-asic-timing-rv32m-divider`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-20 00:38] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求自上而下优化 NPC 时序与 ASIC 风格
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、NPC memory、study 文档、当前 RTL
- `action`: 读取规则与 RTL，定位 EX 组合除法/取模为最高优先级时序风险
- `outputs`: 风险排序与实施边界
- `evidence`: `NpcCore.v` 原 `rv32m_result` 含 `/` 和 `%`
- `handoff_to`: `derive-rtl`
- `next_step`: 四段式推导
- `notes`: cache SRAM 化和 bitmanip/mul 流水化留作后续迭代

### [2026-05-20 00:41] `derive-rtl` - `completed`

- `owner_agent`: `codex`
- `trigger`: RTL 修改前强制四段式推导
- `depends_on`: `recall`
- `inputs`: RV32M 语义、流水线控制、异常/flush 路径
- `action`: 推导需求、协议规则、状态机、不变量和数据通路约束
- `outputs`: 多周期除法器接入方案
- `evidence`: `task-report.md` RTL 推导摘要
- `handoff_to`: `implement-divider`
- `next_step`: 实现 `Rv32Divider` 与 `ex_wait`
- `notes`: fetch fault / illegal 不启动除法，避免异常被长延迟单元阻塞

### [2026-05-20 00:45] `implement-divider` - `completed`

- `owner_agent`: `codex`
- `trigger`: 根据推导落 RTL
- `depends_on`: `derive-rtl`
- `inputs`: `NpcCore.v`、`PipelineControl.v`、`Makefile`
- `action`: 新增 `Rv32Divider.v`，拆除 `rv32m_result` 中 DIV/REM 组合路径，`PipelineControl` 增加 `ex_wait_i`
- `outputs`: 可编译 RTL
- `evidence`: `make -C npc/single lint` PASS
- `handoff_to`: `verify-cputest`
- `next_step`: Verilator build 与 difftest
- `notes`: lint 初次发现冗余高位寄存器，已裁剪成实际需要的位宽

### [2026-05-20 00:50] `verify-cputest` - `completed`

- `owner_agent`: `codex`
- `trigger`: RTL 改动后验证功能等价
- `depends_on`: `implement-divider`
- `inputs`: Verilator NPC、NEMU reference、cpu-tests
- `action`: 先跑定向 `div/mul-longlong/add/load-store/bitmanip`，再跑 cpu-tests 全量
- `outputs`: 38/38 PASS
- `evidence`: `timeout 600s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`
- `handoff_to`: `benchmark-smoke`
- `next_step`: benchmark 长测
- `notes`: 全量列表包含 `div`、`matrix-mul`、`bitmanip`、`fence-i`、`compressed` 等路径

### [2026-05-20 00:52] `benchmark-smoke` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户前序要求 benchmark
- `depends_on`: `verify-cputest`
- `inputs`: CoreMark/Dhrystone benchmark
- `action`: CoreMark 默认 1000 iterations 太长，在 3.6 亿指令处终止；改跑 Dhrystone diff 完整通过
- `outputs`: Dhrystone PASS
- `evidence`: `timeout 600s make -C am-kernels/benchmarks/dhrystone ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0 -F default'`
- `handoff_to`: `record`
- `next_step`: 更新 memory
- `notes`: Dhrystone 提交 `230019182` 条，CPI `3.124`

### [2026-05-20 01:02] `eda-env-check` - `blocked`

- `owner_agent`: `codex`
- `trigger`: ASIC 时序优化需要真实综合/STA 证据
- `depends_on`: `implement-divider`
- `inputs`: `make -C npc/single syn-check-env`
- `action`: 检查综合工具链
- `outputs`: blocked
- `evidence`: 缺少 `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys`
- `handoff_to`: none
- `next_step`: 恢复 oss-cad-suite 后执行 `make -C npc/single syn/sta`
- `notes`: 当前只能给 Verilator lint/build 与 difftest/benchmark 证据，不能给真实 WNS/TNS
