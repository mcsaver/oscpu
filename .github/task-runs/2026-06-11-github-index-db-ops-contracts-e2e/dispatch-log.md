# Dispatch Log

## 基本信息

- `task_id`: 2026-06-11-github-index-db-ops-contracts-e2e
- `task_slug`: github-index-db-ops-contracts-e2e
- `graph_template`: modular-agent-e2e
- `profile`: contracts
- `log_policy`: append-only

---

### [2026-06-11 15:33:48 +0800] `recall-discovery` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:33:48 +0800] `recall-discovery` - `PASS`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:33:48 +0800] `tool-env-check` - `in-progress`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:33:48 +0800] `tool-env-check` - `PASS`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:33:48 +0800] `npc-sim-status` - `in-progress`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:33:48 +0800] `npc-sim-status` - `PASS`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:33:48 +0800] `profile-index` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: .github/e2e/profiles
- `action`: e2e_agent_system_profile_index
- `outputs`: 列出所有可执行 profile
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/profile-index.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:33:48 +0800] `profile-index` - `PASS`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: .github/e2e/profiles
- `action`: e2e_agent_system_profile_index
- `outputs`: 列出所有可执行 profile
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/profile-index.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:33:48 +0800] `ysyx-coordinator-contract` - `in-progress`

- `owner_agent`: ysyx-coordinator
- `module`: ysyx-coordinator
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: coordinator agent + blueprint + profile root
- `action`: e2e_ysyx_coordinator_contract
- `outputs`: 总调度 e2e 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/ysyx-coordinator-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:33:48 +0800] `ysyx-coordinator-contract` - `PASS`

- `owner_agent`: ysyx-coordinator
- `module`: ysyx-coordinator
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: coordinator agent + blueprint + profile root
- `action`: e2e_ysyx_coordinator_contract
- `outputs`: 总调度 e2e 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/ysyx-coordinator-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:33:48 +0800] `hardware-flow-contract` - `in-progress`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: hardware-flow agent + scripts/am-regression.sh + e2e profiles
- `action`: e2e_hardware_flow_contract
- `outputs`: 硬件流程合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/hardware-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:33:48 +0800] `hardware-flow-contract` - `PASS`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: hardware-flow agent + scripts/am-regression.sh + e2e profiles
- `action`: e2e_hardware_flow_contract
- `outputs`: 硬件流程合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/hardware-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:33:48 +0800] `software-flow-contract` - `in-progress`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:33:48 +0800] `software-flow-contract` - `PASS`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:33:48 +0800] `github-index-contract` - `in-progress`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: scripts/github_index_db.py + .github files
- `action`: e2e_github_index_contract
- `outputs`: .github SQLite 索引数据库入口可构建、查询和巡检
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/github-index-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `github-index-contract` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: scripts/github_index_db.py + .github files
- `action`: e2e_github_index_contract
- `outputs`: .github SQLite 索引数据库入口可构建、查询和巡检
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/github-index-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `abstract-machine-contract` - `in-progress`

- `owner_agent`: abstract-machine
- `module`: abstract-machine
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: AM Makefile/scripts/include/memory
- `action`: e2e_abstract_machine_contract
- `outputs`: AM 平台合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/abstract-machine-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `abstract-machine-contract` - `PASS`

- `owner_agent`: abstract-machine
- `module`: abstract-machine
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: AM Makefile/scripts/include/memory
- `action`: e2e_abstract_machine_contract
- `outputs`: AM 平台合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/abstract-machine-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `am-kernels-contract` - `in-progress`

- `owner_agent`: am-kernels
- `module`: am-kernels
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: cpu-tests/am-tests/klib-tests/benchmarks
- `action`: e2e_am_kernels_contract
- `outputs`: 测试与 benchmark 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/am-kernels-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `am-kernels-contract` - `PASS`

- `owner_agent`: am-kernels
- `module`: am-kernels
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: cpu-tests/am-tests/klib-tests/benchmarks
- `action`: e2e_am_kernels_contract
- `outputs`: 测试与 benchmark 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/am-kernels-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `nemu-config-probe` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: nemu Kconfig/configs/device filelist
- `action`: e2e_nemu_config_probe
- `outputs`: NEMU 当前配置和参考入口可见
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/nemu-config-probe.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `nemu-config-probe` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: nemu Kconfig/configs/device filelist
- `action`: e2e_nemu_config_probe
- `outputs`: NEMU 当前配置和参考入口可见
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/nemu-config-probe.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-sim-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/sim + backends
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 统一仿真入口合约存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-sim-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/sim + backends
- `action`: e2e_npc_sim_contract
- `outputs`: NPC 统一仿真入口合约存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-sim-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-single-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/single Makefile/Kconfig/vsrc/csrc
- `action`: e2e_npc_single_contract
- `outputs`: NPC single 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-single-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-single-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/single Makefile/Kconfig/vsrc/csrc
- `action`: e2e_npc_single_contract
- `outputs`: NPC single 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-single-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-soc-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/soc + ysyxSoC CPU ABI
- `action`: e2e_npc_soc_contract
- `outputs`: NPC SoC 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-soc-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-soc-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/soc + ysyxSoC CPU ABI
- `action`: e2e_npc_soc_contract
- `outputs`: NPC SoC 后端合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-soc-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-rv64-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `npc-rv64-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `ysyx-soc-contract` - `in-progress`

- `owner_agent`: ysyx-soc
- `module`: ysyx-soc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: ysyxSoC Makefile/spec/agent/memory
- `action`: e2e_ysyx_soc_contract
- `outputs`: ysyxSoC 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/ysyx-soc-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `ysyx-soc-contract` - `PASS`

- `owner_agent`: ysyx-soc
- `module`: ysyx-soc
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: ysyxSoC Makefile/spec/agent/memory
- `action`: e2e_ysyx_soc_contract
- `outputs`: ysyxSoC 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/ysyx-soc-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `difftest-contract` - `in-progress`

- `owner_agent`: difftest
- `module`: difftest
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: NEMU spike-diff + npc/sim difftest-ref
- `action`: e2e_difftest_contract
- `outputs`: DiffTest 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/difftest-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:42 +0800] `difftest-contract` - `PASS`

- `owner_agent`: difftest
- `module`: difftest
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: NEMU spike-diff + npc/sim difftest-ref
- `action`: e2e_difftest_contract
- `outputs`: DiffTest 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/difftest-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:42 +0800] `yosys-sta-contract` - `in-progress`

- `owner_agent`: yosys-sta
- `module`: yosys-sta
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: yosys-sta Makefile/tools/memory
- `action`: e2e_yosys_sta_contract
- `outputs`: 综合/STA 合约入口和工具状态可见
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/yosys-sta-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `yosys-sta-contract` - `PASS`

- `owner_agent`: yosys-sta
- `module`: yosys-sta
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: yosys-sta Makefile/tools/memory
- `action`: e2e_yosys_sta_contract
- `outputs`: 综合/STA 合约入口和工具状态可见
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/yosys-sta-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:43 +0800] `rv64-linux-contract` - `in-progress`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `rv64-linux-contract` - `PASS`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:43 +0800] `linux-device-contract` - `in-progress`

- `owner_agent`: linux-device
- `module`: linux-device
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: virtio-rootfs instruction + Linux scripts
- `action`: e2e_linux_device_contract
- `outputs`: Linux 设备合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/linux-device-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `linux-device-contract` - `PASS`

- `owner_agent`: linux-device
- `module`: linux-device
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: virtio-rootfs instruction + Linux scripts
- `action`: e2e_linux_device_contract
- `outputs`: Linux 设备合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/linux-device-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:43 +0800] `display-vga-contract` - `in-progress`

- `owner_agent`: display-vga
- `module`: display-vga
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: linux-framebuffer-vga instruction + Linux README
- `action`: e2e_display_vga_contract
- `outputs`: 显示/fbcon 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/display-vga-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `display-vga-contract` - `PASS`

- `owner_agent`: display-vga
- `module`: display-vga
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: linux-framebuffer-vga instruction + Linux README
- `action`: e2e_display_vga_contract
- `outputs`: 显示/fbcon 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/display-vga-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:43 +0800] `verilator-tapeout-contract` - `in-progress`

- `owner_agent`: verilator-tapeout
- `module`: verilator-tapeout
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: verilator realism instruction + npc/rv64
- `action`: e2e_verilator_tapeout_contract
- `outputs`: Verilator-first 流片边界合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/verilator-tapeout-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `verilator-tapeout-contract` - `PASS`

- `owner_agent`: verilator-tapeout
- `module`: verilator-tapeout
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: verilator realism instruction + npc/rv64
- `action`: e2e_verilator_tapeout_contract
- `outputs`: Verilator-first 流片边界合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/verilator-tapeout-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:43 +0800] `fceux-am-contract` - `in-progress`

- `owner_agent`: fceux-am
- `module`: fceux-am
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: fceux-am Makefile/agent/memory
- `action`: e2e_fceux_am_contract
- `outputs`: FCEUX-AM 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/fceux-am-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `fceux-am-contract` - `PASS`

- `owner_agent`: fceux-am
- `module`: fceux-am
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: fceux-am Makefile/agent/memory
- `action`: e2e_fceux_am_contract
- `outputs`: FCEUX-AM 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/fceux-am-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:43 +0800] `nvboard-contract` - `in-progress`

- `owner_agent`: nvboard
- `module`: nvboard
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: nvboard README/scripts/example/agent
- `action`: e2e_nvboard_contract
- `outputs`: NVBoard 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/nvboard-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `nvboard-contract` - `PASS`

- `owner_agent`: nvboard
- `module`: nvboard
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: nvboard README/scripts/example/agent
- `action`: e2e_nvboard_contract
- `outputs`: NVBoard 合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/nvboard-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-11 15:34:43 +0800] `digital-logic-contract` - `in-progress`

- `owner_agent`: digital-logic
- `module`: digital-logic
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: digital_logic_experiment + agent
- `action`: e2e_digital_logic_contract
- `outputs`: 数字逻辑实验合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/digital-logic-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-11 15:34:43 +0800] `digital-logic-contract` - `PASS`

- `owner_agent`: digital-logic
- `module`: digital-logic
- `trigger`: e2e:contracts
- `depends_on`:
- `inputs`: digital_logic_experiment + agent
- `action`: e2e_digital_logic_contract
- `outputs`: 数字逻辑实验合约入口存在
- `evidence`: .github/task-runs/2026-06-11-github-index-db-ops-contracts-e2e/evidence/digital-logic-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:
