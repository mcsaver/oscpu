# Dispatch Log

## 基本信息

- `task_id`: 2026-06-09-nemu-rootfs-machine-info-e2e
- `task_slug`: nemu-rootfs-machine-info-e2e
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `log_policy`: append-only

---

### [2026-06-09 01:55:16 +0800] `recall-discovery` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-09 01:55:16 +0800] `recall-discovery` - `PASS`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-09 01:55:16 +0800] `tool-env-check` - `in-progress`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-09 01:55:16 +0800] `tool-env-check` - `PASS`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-09 01:55:16 +0800] `npc-sim-status` - `in-progress`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-09 01:55:16 +0800] `npc-sim-status` - `PASS`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-09 01:55:16 +0800] `npc-rv64-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-09 01:55:16 +0800] `npc-rv64-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-09 01:55:16 +0800] `rv64-linux-contract` - `in-progress`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-09 01:55:16 +0800] `rv64-linux-contract` - `PASS`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-09 01:55:16 +0800] `nemu-ubuntu-static` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-09 01:55:16 +0800] `nemu-ubuntu-static` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-09 01:55:17 +0800] `rootfs-machine-info-contract` - `PASS`

- `owner_agent`: codex
- `module`: nemu
- `trigger`: 修复 rootfs attached 状态缺少低成本 e2e 证据的缺口。
- `depends_on`: `nemu-ubuntu-static`
- `inputs`: `nemu/src/device/disk.c`、`nemu/src/monitor/monitor.c`、`Linux/Makefile`、`Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64.ext4`
- `action`: 检查 `evidence/nemu-ubuntu-static.log` 中无镜像 detached contract 和 rootfs attached contract。
- `outputs`: `detached/device_id=0/capacity=0` 与 `attached/device_id=2/capacity_bytes=2147483648/capacity_sectors=4194304/readonly=0` 均被 profile 捕获。
- `evidence`: `.github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/nemu-ubuntu-static.log`
- `handoff_to`:
- `next_step`: 记录 memory 和文档，保留真实 guest/systemd gate 作为更深验证。
- `notes`: 该节点是开机前 rootfs/virtio-blk 后端防漂移钩子，不替代完整 Ubuntu guest 运行结论。

### [2026-06-09 01:55:16 +0800] `nemu-ubuntu-slice-contract` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-09 01:55:17 +0800] `nemu-ubuntu-slice-contract` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:
