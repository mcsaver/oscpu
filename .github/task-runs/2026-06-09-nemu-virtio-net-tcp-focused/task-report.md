# Task Report

## 基本信息

- `task_id`: 2026-06-09-nemu-virtio-net-tcp-focused
- `task_slug`: nemu-virtio-net-tcp-focused
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-09 00:30:48 +0800
- `updated_at`: 2026-06-09 00:37:02 +0800

## 任务目标

- `source_request`: 将 agent 系统从纯语言提示升级为分层、分模块、可闭环和可优化的 e2e 流水线
- `goal`: 依据 profile 执行模块化 e2e 节点，生成可复核证据包
- `scope`: profile=nemu-ubuntu-gate；不越级声明未执行模块或业务 gate 已完成

## 选图说明

- `selected_template`: modular-agent-e2e
- `why_this_graph`: 本 profile 从 `.github/e2e/profiles/` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-focused-gate` | `nemu` | `nemu` | `PASS` | optional focused Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行真实 guest gate，否则 SKIP | .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/nemu-ubuntu-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused
- `logs_or_traces`: .github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence
- `profile_manifest`: .github/e2e/profiles/nemu-ubuntu-gate.tsv
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

- `final_result`: profile=nemu-ubuntu-gate 通过，当前 modular e2e 证据链可复用。
- `evidence_summary`: 详见节点表与 `evidence/`
- `notes`: 这是模块化 e2e gate，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate 或 PPA/STA signoff。

## NEMU TCP 切片补充记录

- `slice_result`: PASS。本轮在 hostless DHCP/DNS/ARP/ICMP 之上补齐最小 TCP socket 数据路径；guest 通过普通 `AF_INET/SOCK_STREAM` socket 连接 `10.0.2.2:80`，发送 `GET /nemu-health` 并收到 `HTTP/1.0 204 No Content`。
- `implementation_hooks`: `nemu/src/device/net.c` 新增 `virtio_net_handle_tcp_http()`、`TCP_HTTP_PORT`、TCP IPv4 pseudo-header checksum；`Linux/tools/nemu-systemd-tcp-probe.c` 新增 `SOCK_STREAM`/`SO_BINDTODEVICE` probe；`Linux/scripts/check-nemu-systemd-guest.sh` 新增 TCP probe 构建、注入和 `virtio-net-tcp-http` hard gate；`scripts/e2e/modules/nemu.sh` 新增 TCP source/hook/marker/focused grep contract。
- `focused_evidence`: `.github/task-runs/2026-06-09-nemu-virtio-net-tcp-focused/evidence/nemu-ubuntu-focused-gate.log` 包含 DHCP offer/ack/pass、DNS pass、`__NEMU_TCP_PROBE_CONNECT__:10.0.2.2:80`、`__NEMU_TCP_PROBE_TX__:GET:/nemu-health`、`__NEMU_TCP_PROBE_RX__:HTTP/1.0 204 No Content`、`__NEMU_TCP_PROBE_PASS__:tcp-http`、`__NEMU_CHECK_PASS__:virtio-net-tcp-http`、ICMP pass、TX/RX packets `4/4 -> 9/8`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 与 `HIT GOOD TRAP`。
- `perf`: `boot_seconds=93`, `guest_check_seconds=270`, `poweroff_seconds=8`, `total_seconds=371`。
- `remaining_boundary`: 该切片证明 guest TCP 栈和 NEMU hostless responder 可用；仍不是 TAP/NAT/外网、SSH/apt、真实 host packet backend、通用 TCP server、network stress、multiqueue/control virtqueue 或 QEMU 级网络设备完整性。
