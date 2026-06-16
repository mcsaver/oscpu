# Dispatch Log

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun
- `trace_id`: e2e:2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun
- `task_slug`: 2026-06-16-nemu-python-int-summary-finalize-contract-rerun
- `graph_template`: modular-agent-e2e
- `profile`: nemu-dev-gate
- `log_policy`: append-only

---

### [2026-06-16 15:41:56 +0800] `context-brief` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: .github live index + retained memory/log
- `action`: github-index brief
- `outputs`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/context-brief.md
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/context-brief.md
- `handoff_to`:
- `next_step`: DB-indexed startup context generated before dispatch
- `notes`:

### [2026-06-16 15:41:56 +0800] `profile-resolve` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: .github/e2e/profiles/nemu-dev-gate.tsv
- `action`: github-index resolve-profile
- `outputs`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/profile-resolve.md
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/profile-resolve.md
- `handoff_to`:
- `next_step`: live/indexed e2e profile include closure generated before dispatch
- `notes`:

### [2026-06-16 15:41:56 +0800] `software-flow-contract` - `in-progress`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-16 15:41:56 +0800] `software-flow-contract` - `PASS`

- `owner_agent`: software-flow
- `module`: software-flow
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: software-flow agent + profile + memory
- `action`: e2e_software_flow_contract
- `outputs`: 软件开发全流程 agent 合约入口存在
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/software-flow-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-16 15:41:56 +0800] `nemu-ubuntu-static` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-16 15:42:28 +0800] `nemu-ubuntu-static` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: Linux/NEMU Ubuntu rootfs scripts + performance config
- `action`: e2e_nemu_ubuntu_static_gate
- `outputs`: NEMU Ubuntu 切片静态生产守门 PASS
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-ubuntu-static.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-16 15:42:28 +0800] `nemu-ubuntu-slice-contract` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-16 15:42:30 +0800] `nemu-ubuntu-slice-contract` - `PASS`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: recent NEMU Ubuntu device slice hooks and guest markers
- `action`: e2e_nemu_ubuntu_slice_contract
- `outputs`: 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-ubuntu-slice-contract.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### [2026-06-16 15:42:30 +0800] `nemu-dev-focused-gate` - `in-progress`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: optional NEMU-only Ubuntu rootfs/systemd guest gate
- `action`: e2e_nemu_ubuntu_focused_gate
- `outputs`: AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行 NEMU-only minimized guest gate，否则 SKIP
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-dev-focused-gate.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

### [2026-06-16 15:42:30 +0800] `nemu-dev-focused-gate` - `SKIP`

- `owner_agent`: nemu
- `module`: nemu
- `trigger`: e2e:nemu-dev-gate
- `depends_on`:
- `inputs`: optional NEMU-only Ubuntu rootfs/systemd guest gate
- `action`: e2e_nemu_ubuntu_focused_gate
- `outputs`: AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行 NEMU-only minimized guest gate，否则 SKIP
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/nemu-dev-focused-gate.log
- `handoff_to`:
- `next_step`: 查看 SKIP 原因后切换配置或补依赖
- `notes`:

### [2026-06-16] `manual-fail-path-summary-check` - `PASS`

- `owner_agent`: agent-system
- `module`: nemu
- `trigger`: 验证 `check-nemu-python-int-preflight.sh` 失败路径 summary finalizer
- `depends_on`: `nemu-ubuntu-slice-contract`
- `inputs`: `/bin/false` 作为 NEMU_SIM、dummy Linux/rootfs 输入
- `action`: `bash evidence/check-python-int-summary-fail-finalizer.sh`
- `outputs`: `driver_rc=1`，summary 写出 `status	fail`、`fail_reason	...`、`total_seconds	1`
- `evidence`: `.github/task-runs/2026-06-16-2026-06-16-nemu-python-int-summary-finalize-contract-rerun/evidence/python-int-summary-fail-finalizer/python-int-preflight-summary.tsv`
- `handoff_to`: memory/index
- `next_step`: 更新 memory 并索引 evidence
- `notes`: 该验证不启动真实 NEMU，只覆盖脚本失败记录语义。
