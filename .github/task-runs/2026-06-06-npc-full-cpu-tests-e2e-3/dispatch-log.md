# Dispatch Log

## 基本信息

- `task_id`: 2026-06-06-npc-full-cpu-tests-e2e-3
- `task_slug`: npc-full-cpu-tests-e2e
- `graph_template`: modular-agent-e2e
- `profile`: npc
- `log_policy`: append-only

---

### [2026-06-06 17:40:09 +0800] `recall-discovery` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-06 17:40:09 +0800] `recall-discovery` - `PASS`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-06 17:40:09 +0800] `tool-env-check` - `in-progress`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-06 17:40:09 +0800] `tool-env-check` - `PASS`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-06 17:40:09 +0800] `npc-sim-status` - `in-progress`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-06 17:40:09 +0800] `npc-sim-status` - `PASS`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-06 17:40:09 +0800] `abstract-machine-contract` - `in-progress`

- `owner_agent`: abstract-machine
- `module`: abstract-machine
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: AM Makefile/scripts/include/memory
- `action`: e2e_abstract_machine_contract
- `outputs`: AM 平台合约入口存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/abstract-machine-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-06 17:40:09 +0800] `abstract-machine-contract` - `PASS`

- `owner_agent`: abstract-machine
- `module`: abstract-machine
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: AM Makefile/scripts/include/memory
- `action`: e2e_abstract_machine_contract
- `outputs`: AM 平台合约入口存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/abstract-machine-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-06 17:40:09 +0800] `am-kernels-contract` - `in-progress`

- `owner_agent`: am-kernels
- `module`: am-kernels
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: cpu-tests/am-tests/klib-tests/benchmarks
- `action`: e2e_am_kernels_contract
- `outputs`: 测试与 benchmark 合约入口存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/am-kernels-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-06 17:40:09 +0800] `am-kernels-contract` - `PASS`

- `owner_agent`: am-kernels
- `module`: am-kernels
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: cpu-tests/am-tests/klib-tests/benchmarks
- `action`: e2e_am_kernels_contract
- `outputs`: 测试与 benchmark 合约入口存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/am-kernels-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-06 17:40:09 +0800] `npc-sim-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: npc/sim + backends
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 统一仿真入口合约存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-06 17:40:09 +0800] `npc-sim-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: npc/sim + backends
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 统一仿真入口合约存在
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-06 17:40:09 +0800] `npc-cpu-tests-full` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: riscv32-npc full cpu-tests + npc/sim current backend
- `action`: e2e_npc_cpu_tests_full
- `outputs`: NPC target 全量 cpu-tests PASS
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/npc-cpu-tests-full.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-06 17:40:16 +0800] `npc-cpu-tests-full` - `FAIL`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc
- `depends_on`:
- `inputs`: riscv32-npc full cpu-tests + npc/sim current backend
- `action`: e2e_npc_cpu_tests_full
- `outputs`: exit=1
- `evidence`: .github/task-runs/2026-06-06-npc-full-cpu-tests-e2e-3/evidence/npc-cpu-tests-full.log
- `handoff_to`:
- `next_step`: 检查日志并按 regression-debug-loop 扩图
- `notes`:
