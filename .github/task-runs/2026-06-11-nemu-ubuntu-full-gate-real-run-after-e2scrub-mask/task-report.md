# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask
- `task_slug`: nemu-ubuntu-full-gate-real-run-after-e2scrub-mask
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-full-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-11 03:55:19 +0800
- `updated_at`: 2026-06-11 04:08:36 +0800

## 任务目标

- `source_request`: 通过 `nemu-ubuntu-full-gate` profile 真实运行完整 Ubuntu 22.04 full rootfs focused gate
- `goal`: 验证 e2scrub mask 修复后，full rootfs focused gate 能在新 profile 中真实 PASS
- `scope`: profile=nemu-ubuntu-full-gate；证明 full server-like rootfs 的 NEMU/systemd focused gate，不越级声明 QEMU 等价、SMP/PCI/TAP/NAT/snapshot、桌面 Ubuntu 或长期 soak

## 选图说明

- `selected_template`: modular-agent-e2e
- `why_this_graph`: 本 profile 从 `.github/e2e/profiles/` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | agent-env + bash/git/make/python/gcc/verilator/toolchain | 非交互软环境、hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/rv64-linux-contract.log |
| `software-flow-contract` | `software-flow` | `software-flow` | `PASS` | software-flow agent + profile + memory | 软件开发全流程 agent 合约入口存在 | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/software-flow-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-full-focused-gate` | `nemu` | `nemu` | `PASS` | optional full Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 时运行真实 full rootfs guest gate，否则 SKIP | .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence/nemu-ubuntu-full-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask
- `logs_or_traces`: .github/task-runs/2026-06-11-nemu-ubuntu-full-gate-real-run-after-e2scrub-mask/evidence
- `profile_manifest`: .github/e2e/profiles/nemu-ubuntu-full-gate.tsv
- `linked_memory_updates`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 见对应 tool/env 节点日志
- `risk_assessment`: 无 hard fail；optional tool 缺失只作为后续节点风险。

## 下一步建议

1. 按模块或跨模块目标选择更深 profile，或进入具体静态图。
2. 对含 `SKIP` 的模块，先补依赖或切换到合适配置，再把该模块提升到 PASS 证据。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 已作为 modular-agent-e2e profile 固化
- `reason`: profile + module library + task-run 证据包能把 agent 提示转为可执行流水线

## 收尾结论

- `final_result`: profile=nemu-ubuntu-full-gate 真实 PASS，`nemu-ubuntu-full-focused-gate` 节点执行了 `check-nemu-systemd-guest-full` 并通过。
- `evidence_summary`: full console 含 `systemd-running`、`systemd-jobs`、`systemd-target-multi-user.target`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 和 `HIT GOOD TRAP`；readiness 日志含 e2scrub reap/timer mask；perf 为 `boot=142s guest_check=621s poweroff=14s total=777s`。
- `notes`: 这是 full rootfs focused gate 的 profile 级证据，不替代 QEMU 等价、SMP/PCI/TAP/NAT/snapshot、桌面 Ubuntu、长期 soak、DiffTest 或 PPA/STA signoff。
