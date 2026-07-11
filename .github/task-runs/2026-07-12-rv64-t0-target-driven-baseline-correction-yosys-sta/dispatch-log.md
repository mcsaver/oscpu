# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta
- `trace_id`: e2e:2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta
- `task_slug`: rv64-t0-target-driven-baseline-correction-yosys-sta
- `graph_template`: modular-agent-e2e
- `profile`: yosys-sta
- `log_policy`: append-only

---

### [2026-07-12 03:06:48 +0800] `context-brief` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: .github live index + retained memory/log
- `action`: github-index brief
- `outputs`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/context-brief.md
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/context-brief.md
- `handoff_to`:
- `next_step`: DB-indexed startup context generated before dispatch
- `notes`:

### [2026-07-12 03:06:48 +0800] `profile-resolve` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: .github/e2e/profiles/yosys-sta.tsv
- `action`: github-index resolve-profile
- `outputs`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/profile-resolve.md
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/profile-resolve.md
- `handoff_to`:
- `next_step`: live/indexed e2e profile include closure generated before dispatch
- `notes`:

### [2026-07-12 03:06:48 +0800] `recall-discovery` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-07-12 03:06:49 +0800] `recall-discovery` - `PASS`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-07-12 03:06:49 +0800] `tool-env-check` - `in-progress`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-07-12 03:06:49 +0800] `tool-env-check` - `PASS`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-07-12 03:06:49 +0800] `npc-sim-status` - `in-progress`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-07-12 03:06:49 +0800] `npc-sim-status` - `PASS`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-07-12 03:06:49 +0800] `npc-sim-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: npc/sim + backends
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 统一仿真入口合约存在
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-07-12 03:06:49 +0800] `npc-sim-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: npc/sim + backends
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 统一仿真入口合约存在
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-07-12 03:06:49 +0800] `npc-single-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: npc/single Makefile/Kconfig/vsrc/csrc
- `action`: e2e_npc_single_contract
- `outputs`: NPC single 后端合约入口存在
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/npc-single-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-07-12 03:06:49 +0800] `npc-single-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: npc/single Makefile/Kconfig/vsrc/csrc
- `action`: e2e_npc_single_contract
- `outputs`: NPC single 后端合约入口存在
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/npc-single-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-07-12 03:06:49 +0800] `yosys-sta-contract` - `in-progress`

- `owner_agent`: yosys-sta
- `module`: yosys-sta
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: yosys-sta Makefile/tools/memory
- `action`: e2e_yosys_sta_contract
- `outputs`: 综合/STA 合约入口和工具状态可见
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/yosys-sta-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-07-12 03:06:49 +0800] `yosys-sta-contract` - `PASS`

- `owner_agent`: yosys-sta
- `module`: yosys-sta
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: yosys-sta Makefile/tools/memory
- `action`: e2e_yosys_sta_contract
- `outputs`: 综合/STA 合约入口和工具状态可见
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/yosys-sta-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-07-12 03:06:49 +0800] `yosys-sta-contract-fail-closed` - `in-progress`

- `owner_agent`: yosys-sta
- `module`: yosys-sta
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: yosys-sta contract return-code path
- `action`: e2e_yosys_sta_contract_failure_propagation
- `outputs`: 综合/STA 合同失败不可被后续成功命令覆盖
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/yosys-sta-contract-fail-closed.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-07-12 03:06:49 +0800] `yosys-sta-contract-fail-closed` - `PASS`

- `owner_agent`: yosys-sta
- `module`: yosys-sta
- `trigger`: e2e:yosys-sta
- `depends_on`:
- `inputs`: yosys-sta contract return-code path
- `action`: e2e_yosys_sta_contract_failure_propagation
- `outputs`: 综合/STA 合同失败不可被后续成功命令覆盖
- `evidence`: .github/task-runs/2026-07-12-rv64-t0-target-driven-baseline-correction-yosys-sta/evidence/yosys-sta-contract-fail-closed.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:
