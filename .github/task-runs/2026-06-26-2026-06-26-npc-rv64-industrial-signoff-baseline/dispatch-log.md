# Dispatch Log

## 基本信息

- `task_id`: 2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline
- `trace_id`: e2e:2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline
- `task_slug`: 2026-06-26-npc-rv64-industrial-signoff-baseline
- `graph_template`: modular-agent-e2e
- `profile`: npc-dev
- `log_policy`: append-only

---

### [2026-06-26 15:02:06 +0800] `context-brief` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: .github live index + retained memory/log
- `action`: github-index brief
- `outputs`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/context-brief.md
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/context-brief.md
- `handoff_to`:
- `next_step`: DB-indexed startup context generated before dispatch
- `notes`:

### [2026-06-26 15:02:06 +0800] `profile-resolve` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: .github/e2e/profiles/npc-dev.tsv
- `action`: github-index resolve-profile
- `outputs`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/profile-resolve.md
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/profile-resolve.md
- `handoff_to`:
- `next_step`: live/indexed e2e profile include closure generated before dispatch
- `notes`:

### [2026-06-26 15:02:06 +0800] `software-flow-contract` - `in-progress`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-26 15:02:06 +0800] `software-flow-contract` - `PASS`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-sim-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/sim + backend manifests
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 开发环境入口只检查 NPC 仿真后端合同
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-sim-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/sim + backend manifests
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 开发环境入口只检查 NPC 仿真后端合同
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-single-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/single Makefile/Kconfig/vsrc/csrc
- `action`: e2e_npc_single_contract
- `outputs`: NPC single 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-single-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-single-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/single Makefile/Kconfig/vsrc/csrc
- `action`: e2e_npc_single_contract
- `outputs`: NPC single 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-single-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-soc-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/soc + ysyxSoC CPU ABI
- `action`: e2e_npc_soc_contract
- `outputs`: NPC SoC 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-soc-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-soc-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/soc + ysyxSoC CPU ABI
- `action`: e2e_npc_soc_contract
- `outputs`: NPC SoC 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-soc-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-rv64-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: NPC RV64 Linux 入口合约存在但不跑 NEMU Ubuntu gate
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-26 15:02:06 +0800] `npc-rv64-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:npc-dev
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: NPC RV64 Linux 入口合约存在但不跑 NEMU Ubuntu gate
- `evidence`: .github/task-runs/2026-06-26-2026-06-26-npc-rv64-industrial-signoff-baseline/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:
