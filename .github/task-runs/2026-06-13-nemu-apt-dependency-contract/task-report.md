# Task Report

## 基本信息

- `task_id`: 2026-06-13-nemu-apt-dependency-contract
- `task_slug`: nemu-apt-dependency-contract
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-13 08:13:01 +0800
- `updated_at`: 2026-06-13 08:27:27 +0800

## 任务目标

- `source_request`: 将 agent 系统从纯语言提示升级为分层、分模块、可闭环和可优化的 e2e 流水线
- `goal`: 依据 profile 执行模块化 e2e 节点，生成可复核证据包
- `scope`: profile=nemu-ubuntu；不越级声明未执行模块或业务 gate 已完成

## 选图说明

- `selected_template`: modular-agent-e2e
- `why_this_graph`: 本 profile 从 `.github/e2e/profiles/` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | agent-env + bash/git/make/python/gcc/verilator/toolchain | 非交互软环境、hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/npc-rv64-contract.log |
| `npc-rv64-sv39-sret-u-mode` | `npc` | `npc` | `PASS` | npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB | NPC RV64 SRET 到 U-mode、U 页取指、U ecall、U load page fault 回 S 并 sret 回 U 的回归 PASS | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/npc-rv64-sv39-sret-u-mode.log |
| `npc-rv64-linux-focused-smokes` | `npc` | `npc` | `PASS` | Linux/tools SRET/Sv39/pagefault/virtio focused smokes on NPC | NPC RV64 Linux focused smokes 覆盖 SRET/Sv39、ret_from_exception、U pagefault 与 virtio-blk | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/npc-rv64-linux-focused-smokes.log |
| `npc-rv64-uart-rx-smoke` | `npc` | `npc` | `PASS` | NPC 16550 UART RX register + gated DPI injection smoke | NPC RV64 UART RX 支持 RBR/LSR/IIR/IER[0]，并支持 NPC_UART_RX_WAIT 按 guest 输出 marker 释放宿主输入 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/npc-rv64-uart-rx-smoke.log |
| `npc-rv64-linux-rootfs-mount-smoke` | `npc` | `npc` | `PASS` | Ubuntu rootfs mount + systemd banner smoke on NPC | NPC RV64 Ubuntu rootfs 至少完成 ttyS0 console、virtio-blk、EXT4/VFS root mount，并进入 systemd PID1 打印 Ubuntu 22.04 banner | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/npc-rv64-linux-rootfs-mount-smoke.log |
| `npc-rv64-systemd-guest-check-contract` | `npc` | `npc` | `PASS` | NPC systemd guest prompt/script gate contract | NPC RV64 具备等待 root 串口 prompt 后用 NPC_UART_RX_FILE 注入 guest-side 检查脚本并等待 NPC_GUEST_EXPECT marker 的 gate 入口 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/npc-rv64-systemd-guest-check-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/rv64-linux-contract.log |
| `software-flow-contract` | `software-flow` | `software-flow` | `PASS` | software-flow agent + profile + memory | 软件开发全流程 agent 合约入口存在 | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/software-flow-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence/nemu-ubuntu-slice-contract.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-13-nemu-apt-dependency-contract
- `logs_or_traces`: .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence
- `context_brief`: .github/task-runs/2026-06-13-nemu-apt-dependency-contract/context-brief.md
- `profile_resolve`: .github/task-runs/2026-06-13-nemu-apt-dependency-contract/profile-resolve.md
- `evidence_index`: .github/task-runs/2026-06-13-nemu-apt-dependency-contract/evidence-index.md
- `profile_manifest`: .github/e2e/profiles/nemu-ubuntu.tsv
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

- `final_result`: profile=nemu-ubuntu 通过，当前 modular e2e 证据链可复用。
- `evidence_summary`: 详见节点表与 `evidence/`
- `notes`: 这是模块化 e2e gate，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate 或 PPA/STA signoff。
