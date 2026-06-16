# Task Report

## 基本信息

- `task_id`: 2026-06-08-nemu-virtio-net-dhcp-raw-focused
- `task_slug`: nemu-virtio-net-dhcp-raw-focused
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-08 23:38:20 +0800
- `updated_at`: 2026-06-08 23:44:09 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-focused-gate` | `nemu` | `nemu` | `PASS` | optional focused Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行真实 guest gate，否则 SKIP | .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence/nemu-ubuntu-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused
- `logs_or_traces`: .github/task-runs/2026-06-08-nemu-virtio-net-dhcp-raw-focused/evidence
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

## NEMU DHCP 切片补充记录

- `slice_result`: 本 focused run 证明 NEMU virtio-net 的 hostless DHCP/ARP/ICMP 最小闭环可在真实 Ubuntu rootfs guest 中运行。DHCP probe 在 `eth0` 无 IPv4 地址时先完成 Discover/Offer/Request/Ack，拿到 `10.0.2.15` lease；随后 guest-check 继续走静态 IPv4 fallback 和 `10.0.2.2` ICMP echo。
- `implementation_hooks`: `nemu/src/device/net.c` 新增 `virtio_net_handle_dhcp`、DHCP option/message constants、IPv4 UDP 67->68 reply 构造；`Linux/tools/nemu-systemd-dhcp-probe.c` 使用 `AF_PACKET`/`SOCK_RAW` 构造 raw Ethernet DHCP client；`Linux/scripts/check-nemu-systemd-guest.sh` 新增 DHCP probe build/inject/run 和 `virtio-net-dhcp-lease` hard marker；`scripts/e2e/modules/nemu.sh` 检查 DHCP probe 源码、guest marker、focused grep 和 NEMU DHCP hook。
- `root_cause_history`: 首版 DHCP probe 使用普通 UDP socket，在 guest 接口尚未配置 IPv4 时 focused gate 失败，现象为 `__NEMU_DHCP_PROBE_TX__:discover:eth0` 后 `__NEMU_DHCP_PROBE_FAIL__:recv:Resource temporarily unavailable`；同时 TX/RX packets 已增长，说明 NEMU responder 有回复但 socket 层收不到。稳定修复是改为 raw packet DHCP probe。
- `focused_evidence`: 最终 run 包含 `__NEMU_DHCP_PROBE_TX__:discover:eth0`、`__NEMU_DHCP_PROBE_OFFER__:10.0.2.15:10.0.2.2`、`__NEMU_DHCP_PROBE_TX__:request:eth0`、`__NEMU_DHCP_PROBE_ACK__:10.0.2.15:10.0.2.2`、`__NEMU_DHCP_PROBE_PASS__:dhcp-lease`、`__NEMU_CHECK_PASS__:virtio-net-dhcp-lease`、后续 `__NEMU_ICMP_PROBE_PASS__:icmp-echo`、TX/RX packets `4/4`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 和 `HIT GOOD TRAP`。`perf.tsv` 为 `boot_seconds=91`、`guest_check_seconds=248`、`poweroff_seconds=8`、`total_seconds=347`。
- `remaining_boundary`: 这不是 TAP/NAT/外网收发、真实 host packet backend、network stress、control virtqueue/multiqueue、SMP、snapshot/GDB/monitor、完整 TB cache 或 DBT/JIT；它只闭合当前 hostless DHCP/ARP/ICMP 切片。
