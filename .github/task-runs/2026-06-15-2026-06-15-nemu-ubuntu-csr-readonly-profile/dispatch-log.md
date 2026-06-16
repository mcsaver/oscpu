# Dispatch Log

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile
- `trace_id`: e2e:2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile
- `task_slug`: 2026-06-15-nemu-ubuntu-csr-readonly-profile
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-profile
- `log_policy`: append-only

---

### [2026-06-15 17:38:09 +0800] `context-brief` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: .github live index + retained memory/log
- `action`: github-index brief
- `outputs`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/context-brief.md
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/context-brief.md
- `handoff_to`:
- `next_step`: DB-indexed startup context generated before dispatch
- `notes`:

### [2026-06-15 17:38:09 +0800] `profile-resolve` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: .github/e2e/profiles/nemu-ubuntu-profile.tsv
- `action`: github-index resolve-profile
- `outputs`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/profile-resolve.md
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/profile-resolve.md
- `handoff_to`:
- `next_step`: live/indexed e2e profile include closure generated before dispatch
- `notes`:

### [2026-06-15 17:38:09 +0800] `software-flow-contract` - `in-progress`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-15 17:38:09 +0800] `software-flow-contract` - `PASS`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-15 17:38:09 +0800] `nemu-ubuntu-static` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-15 17:38:37 +0800] `nemu-ubuntu-static` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-15 17:38:37 +0800] `nemu-ubuntu-slice-contract` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-15 17:38:39 +0800] `nemu-ubuntu-slice-contract` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-15 17:38:39 +0800] `nemu-ubuntu-profile` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: NEMU_PROFILE=1 full Ubuntu boot budget with guest tests off
- `action`: e2e_nemu_ubuntu_profile_gate
- `outputs`: profile-summary.txt console.log nemu.log
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/nemu-ubuntu-profile.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-15 17:39:19 +0800] `nemu-ubuntu-profile` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-ubuntu-profile
- `depends_on`:
- `inputs`: NEMU_PROFILE=1 full Ubuntu boot budget with guest tests off
- `action`: e2e_nemu_ubuntu_profile_gate
- `outputs`: profile-summary.txt console.log nemu.log
- `evidence`: .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-readonly-profile/evidence/nemu-ubuntu-profile.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:
