# Dispatch Log

## 基本信息

- `task_id`: 2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix
- `trace_id`: e2e:2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix
- `task_slug`: 2026-06-14-nemu-full-service-workload-contract-rsyslog-fix
- `graph_template`: modular-agent-e2e
- `profile`: nemu-dev-gate
- `log_policy`: append-only

---

### [2026-06-14 03:18:28 +0800] `context-brief` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: .github DB stored memory
- `action`: github-index brief
- `outputs`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/context-brief.md
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/context-brief.md
- `handoff_to`:
- `next_step`: DB-backed startup context generated before dispatch
- `notes`:

### [2026-06-14 03:18:28 +0800] `profile-resolve` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: .github/e2e/profiles/nemu-dev-gate.tsv
- `action`: github-index resolve-profile
- `outputs`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/profile-resolve.md
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/profile-resolve.md
- `handoff_to`:
- `next_step`: DB-backed e2e profile include closure generated before dispatch
- `notes`:

### [2026-06-14 03:18:28 +0800] `software-flow-contract` - `in-progress`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-14 03:18:30 +0800] `software-flow-contract` - `PASS`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-14 03:18:30 +0800] `nemu-ubuntu-static` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-14 03:18:56 +0800] `nemu-ubuntu-static` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-14 03:18:56 +0800] `nemu-ubuntu-slice-contract` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-14 03:18:59 +0800] `nemu-ubuntu-slice-contract` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-14 03:18:59 +0800] `nemu-dev-focused-gate` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: optional NEMU-only Ubuntu rootfs/systemd guest gate
- `action`: e2e_nemu_ubuntu_focused_gate
- `outputs`: AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行 NEMU-only minimized guest gate，否则 SKIP
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/nemu-dev-focused-gate.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-14 03:18:59 +0800] `nemu-dev-focused-gate` - `SKIP`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: optional NEMU-only Ubuntu rootfs/systemd guest gate
- `action`: e2e_nemu_ubuntu_focused_gate
- `outputs`: AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行 NEMU-only minimized guest gate，否则 SKIP
- `evidence`: .github/task-runs/2026-06-14-2026-06-14-nemu-full-service-workload-contract-rsyslog-fix/evidence/nemu-dev-focused-gate.log
- `handoff_to`:
- `next_step`: 查看 SKIP 原因后切换配置或补依赖
- `notes`:
