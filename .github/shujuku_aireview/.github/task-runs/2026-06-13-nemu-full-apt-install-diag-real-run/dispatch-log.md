# Dispatch Log

## 基本信息

- `task_id`: 2026-06-13-nemu-full-apt-install-diag-real-run
- `task_slug`: nemu-full-apt-install-diag-real-run
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-full-gate
- `log_policy`: append-only

---

### [2026-06-13 02:14:59 +0800] `context-brief` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: .github DB stored memory
- `action`: github-index brief
- `outputs`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/context-brief.md
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/context-brief.md
- `handoff_to`:
- `next_step`: DB-backed startup context generated before dispatch
- `notes`:

### [2026-06-13 02:14:59 +0800] `profile-resolve` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: .github/e2e/profiles/nemu-ubuntu-full-gate.tsv
- `action`: github-index resolve-profile
- `outputs`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/profile-resolve.md
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/profile-resolve.md
- `handoff_to`:
- `next_step`: DB-backed e2e profile include closure generated before dispatch
- `notes`:

### [2026-06-13 02:14:59 +0800] `recall-discovery` - `in-progress`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:15:00 +0800] `recall-discovery` - `PASS`

- `owner_agent`: agent-system
- `module`: agent-system
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: AGENTS/copilot/instructions/memory/e2e profiles
- `action`: e2e_agent_system_discovery
- `outputs`: 规则发现链和 e2e 配置入口存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:15:00 +0800] `tool-env-check` - `in-progress`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:15:00 +0800] `tool-env-check` - `PASS`

- `owner_agent`: agent-system
- `module`: toolchain
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: agent-env + bash/git/make/python/gcc/verilator/toolchain
- `action`: e2e_toolchain_check
- `outputs`: 非交互软环境、hard requirements 与 optional tools 可见
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/tool-env-check.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:15:00 +0800] `npc-sim-status` - `in-progress`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:15:00 +0800] `npc-sim-status` - `PASS`

- `owner_agent`: hardware-flow
- `module`: hardware-flow
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: npc/sim Kconfig 与 backend mk
- `action`: e2e_hardware_flow_npc_sim_status
- `outputs`: 当前 npc/sim 后端状态
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-sim-status.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:15:00 +0800] `npc-rv64-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:15:00 +0800] `npc-rv64-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: npc/rv64 + Linux README
- `action`: e2e_npc_rv64_contract
- `outputs`: RV64 core/Linux 入口合约存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:15:00 +0800] `npc-rv64-sv39-sret-u-mode` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB
- `action`: e2e_npc_rv64_sv39_sret_u_mode
- `outputs`: NPC RV64 SRET 到 U-mode、U 页取指、U ecall、U load page fault 回 S 并 sret 回 U 的回归 PASS
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-sv39-sret-u-mode.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:15:01 +0800] `npc-rv64-sv39-sret-u-mode` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB
- `action`: e2e_npc_rv64_sv39_sret_u_mode
- `outputs`: NPC RV64 SRET 到 U-mode、U 页取指、U ecall、U load page fault 回 S 并 sret 回 U 的回归 PASS
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-sv39-sret-u-mode.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:15:01 +0800] `npc-rv64-linux-focused-smokes` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Linux/tools SRET/Sv39/pagefault/virtio focused smokes on NPC
- `action`: e2e_npc_rv64_linux_focused_smokes
- `outputs`: NPC RV64 Linux focused smokes 覆盖 SRET/Sv39、ret_from_exception、U pagefault 与 virtio-blk
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-linux-focused-smokes.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:15:01 +0800] `npc-rv64-linux-focused-smokes` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Linux/tools SRET/Sv39/pagefault/virtio focused smokes on NPC
- `action`: e2e_npc_rv64_linux_focused_smokes
- `outputs`: NPC RV64 Linux focused smokes 覆盖 SRET/Sv39、ret_from_exception、U pagefault 与 virtio-blk
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-linux-focused-smokes.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:15:01 +0800] `npc-rv64-uart-rx-smoke` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: NPC 16550 UART RX register + gated DPI injection smoke
- `action`: e2e_npc_rv64_uart_rx_smoke
- `outputs`: NPC RV64 UART RX 支持 RBR/LSR/IIR/IER[0]，并支持 NPC_UART_RX_WAIT 按 guest 输出 marker 释放宿主输入
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-uart-rx-smoke.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:15:21 +0800] `npc-rv64-uart-rx-smoke` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: NPC 16550 UART RX register + gated DPI injection smoke
- `action`: e2e_npc_rv64_uart_rx_smoke
- `outputs`: NPC RV64 UART RX 支持 RBR/LSR/IIR/IER[0]，并支持 NPC_UART_RX_WAIT 按 guest 输出 marker 释放宿主输入
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-uart-rx-smoke.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:15:21 +0800] `npc-rv64-linux-rootfs-mount-smoke` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Ubuntu rootfs mount + systemd banner smoke on NPC
- `action`: e2e_npc_rv64_linux_rootfs_mount_smoke
- `outputs`: NPC RV64 Ubuntu rootfs 至少完成 ttyS0 console、virtio-blk、EXT4/VFS root mount，并进入 systemd PID1 打印 Ubuntu 22.04 banner
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:28:45 +0800] `npc-rv64-linux-rootfs-mount-smoke` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Ubuntu rootfs mount + systemd banner smoke on NPC
- `action`: e2e_npc_rv64_linux_rootfs_mount_smoke
- `outputs`: NPC RV64 Ubuntu rootfs 至少完成 ttyS0 console、virtio-blk、EXT4/VFS root mount，并进入 systemd PID1 打印 Ubuntu 22.04 banner
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:28:45 +0800] `npc-rv64-systemd-guest-check-contract` - `in-progress`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: NPC systemd guest prompt/script gate contract
- `action`: e2e_npc_rv64_systemd_guest_check_contract
- `outputs`: NPC RV64 具备等待 root 串口 prompt 后用 NPC_UART_RX_FILE 注入 guest-side 检查脚本并等待 NPC_GUEST_EXPECT marker 的 gate 入口
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-systemd-guest-check-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:28:45 +0800] `npc-rv64-systemd-guest-check-contract` - `PASS`

- `owner_agent`: npc
- `module`: npc
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: NPC systemd guest prompt/script gate contract
- `action`: e2e_npc_rv64_systemd_guest_check_contract
- `outputs`: NPC RV64 具备等待 root 串口 prompt 后用 NPC_UART_RX_FILE 注入 guest-side 检查脚本并等待 NPC_GUEST_EXPECT marker 的 gate 入口
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/npc-rv64-systemd-guest-check-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:28:45 +0800] `rv64-linux-contract` - `in-progress`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:28:45 +0800] `rv64-linux-contract` - `PASS`

- `owner_agent`: rv64-linux
- `module`: rv64-linux
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Linux Makefile/env/platform/instructions
- `action`: e2e_rv64_linux_contract
- `outputs`: RV64 Linux/Ubuntu 合约入口存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/rv64-linux-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:28:45 +0800] `software-flow-contract` - `in-progress`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:28:49 +0800] `software-flow-contract` - `PASS`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:28:49 +0800] `nemu-ubuntu-static` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:29:13 +0800] `nemu-ubuntu-static` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:29:13 +0800] `nemu-ubuntu-slice-contract` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 02:29:15 +0800] `nemu-ubuntu-slice-contract` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-13 02:29:15 +0800] `nemu-ubuntu-full-focused-gate` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: optional full Ubuntu rootfs/systemd guest gate
- `action`: e2e_nemu_ubuntu_full_focused_gate
- `outputs`: AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 时运行真实 full rootfs guest gate，否则 SKIP
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/nemu-ubuntu-full-focused-gate.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-13 03:21:43 +0800] `nemu-ubuntu-full-focused-gate` - `FAIL`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-full-gate
- `depends_on`:
- `inputs`: optional full Ubuntu rootfs/systemd guest gate
- `action`: e2e_nemu_ubuntu_full_focused_gate
- `outputs`: exit=2
- `evidence`: .github/task-runs/2026-06-13-nemu-full-apt-install-diag-real-run/evidence/nemu-ubuntu-full-focused-gate.log
- `handoff_to`:
- `next_step`: 检查日志并按 regression-debug-loop 扩图
- `notes`:
