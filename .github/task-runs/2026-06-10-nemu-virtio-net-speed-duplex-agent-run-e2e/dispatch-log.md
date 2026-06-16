# Dispatch Log

## 基本信息

- `task_id`: 2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e
- `task_slug`: nemu-virtio-net-speed-duplex-agent-run-e2e
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `log_policy`: append-only

---

### [2026-06-10 22:50:11 +0800] `recall-discovery` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:11 +0800] `recall-discovery` - `FAIL`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: exit=1
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 检查日志并按 regression-debug-loop 扩图
- `notes`:

### [2026-06-10 22:50:11 +0800] `tool-env-check` - `in-progress`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:11 +0800] `tool-env-check` - `PASS`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-10 22:50:11 +0800] `npc-sim-status` - `in-progress`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:11 +0800] `npc-sim-status` - `PASS`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-10 22:50:11 +0800] `npc-rv64-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:11 +0800] `npc-rv64-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-10 22:50:11 +0800] `rv64-linux-contract` - `in-progress`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:11 +0800] `rv64-linux-contract` - `PASS`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-10 22:50:11 +0800] `software-flow-contract` - `in-progress`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:11 +0800] `software-flow-contract` - `PASS`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-10 22:50:11 +0800] `nemu-ubuntu-static` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:29 +0800] `nemu-ubuntu-static` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-10 22:50:29 +0800] `nemu-ubuntu-slice-contract` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-10 22:50:30 +0800] `nemu-ubuntu-slice-contract` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-10-nemu-virtio-net-speed-duplex-agent-run-e2e/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:
