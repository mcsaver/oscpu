# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-full-ssh-service-real-run
- `task_slug`: nemu-full-ssh-service-real-run
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-full-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-11 06:50:09 +0800
- `updated_at`: 2026-06-11 07:04:23 +0800

## 任务目标

- `source_request`: 将 agent 系统从纯语言提示升级为分层、分模块、可闭环和可优化的 e2e 流水线
- `goal`: 依据 profile 执行模块化 e2e 节点，生成可复核证据包
- `scope`: profile=nemu-ubuntu-full-gate；不越级声明未执行模块或业务 gate 已完成

## 选图说明

- `selected_template`: modular-agent-e2e
- `why_this_graph`: 本 profile 从 `.github/e2e/profiles/` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | agent-env + bash/git/make/python/gcc/verilator/toolchain | 非交互软环境、hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/rv64-linux-contract.log |
| `software-flow-contract` | `software-flow` | `software-flow` | `PASS` | software-flow agent + profile + memory | 软件开发全流程 agent 合约入口存在 | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/software-flow-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-full-focused-gate` | `nemu` | `nemu` | `PASS` | optional full Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 时运行真实 full rootfs guest gate，否则 SKIP | .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence/nemu-ubuntu-full-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run
- `logs_or_traces`: .github/task-runs/2026-06-11-nemu-full-ssh-service-real-run/evidence
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

- `final_result`: profile=nemu-ubuntu-full-gate 通过，当前 modular e2e 证据链可复用。
- `evidence_summary`: 详见节点表与 `evidence/`
- `notes`: 这是模块化 e2e gate，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate 或 PPA/STA signoff。

## 人工追加结论

- `implemented_slice`: full Ubuntu 22.04 rootfs 的 OpenSSH runtime gate 从 `sshd -T`/unit 存在推进到 `ssh.service` active 与 22 端口 LISTEN。
- `evidence`: console 含 `__NEMU_CHECK_FULL_SSH_ACTIVE__:active`、`__NEMU_CHECK_FULL_SSH_LISTEN_SOCKET__:/proc/net/tcp:00000000:0016:0A`、`__NEMU_CHECK_PASS__:full-userland-ssh-active`、`__NEMU_CHECK_PASS__:full-userland-ssh-listen`、`__NEMU_CHECK_PASS__:full-userland-runtime`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 和 GOOD TRAP；wrapper 含 ssh active/listen/runtime 三个 focused full userland marker。
- `negative_scan`: `__NEMU_CHECK_FAIL__`、BAD TRAP、kernel panic/oops、EXT4/I/O error、SIGILL/illegal instruction/unhandled signal 均无命中。
- `boundary`: 本切片证明 guest 内 sshd 服务和本地监听 socket，不证明 TAP/NAT/外网 SSH 登录、端口转发、真实 host 网络后端、桌面 Ubuntu、SMP/PCI/snapshot 或 QEMU 等价。
