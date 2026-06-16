# Task Report

## 基本信息

- `task_id`: 2026-06-09-nemu-virtio-net-dns-focused
- `task_slug`: nemu-virtio-net-dns-focused
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-09 00:06:25 +0800
- `updated_at`: 2026-06-09 00:12:28 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-focused-gate` | `nemu` | `nemu` | `PASS` | optional focused Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行真实 guest gate，否则 SKIP | .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence/nemu-ubuntu-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused
- `logs_or_traces`: .github/task-runs/2026-06-09-nemu-virtio-net-dns-focused/evidence
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

## NEMU DNS 切片补充记录

- `slice_result`: 本 focused run 证明 NEMU virtio-net 的 hostless DHCP/DNS/ARP/ICMP 最小网络闭环可在真实 Ubuntu rootfs guest 中运行。DHCP probe 先完成 Discover/Offer/Request/Ack，DNS probe 随后通过 UDP socket 查询 `nemu.local`，收到 A 记录 `10.0.2.2`，再继续 ICMP echo。
- `implementation_hooks`: `nemu/src/device/net.c` 新增 `virtio_net_handle_dns` 与 `DNS_QTYPE_A` 等 DNS 常量，只回答 `nemu.local A/IN -> 10.0.2.2`；`Linux/tools/nemu-systemd-dns-probe.c` 使用 `SOCK_DGRAM` 与 `SO_BINDTODEVICE` 验证 guest IPv4/ARP/UDP/DNS 路径；`Linux/scripts/check-nemu-systemd-guest.sh` 新增 DNS probe build/inject/run 和 `virtio-net-dns-a` hard marker；`scripts/e2e/modules/nemu.sh` 检查 DNS probe 源码、guest marker、focused grep 和 NEMU DNS hook。
- `focused_evidence`: 最终 run 包含 `__NEMU_DHCP_PROBE_PASS__:dhcp-lease`、`__NEMU_DNS_PROBE_TX__:nemu.local:10.0.2.2`、`__NEMU_DNS_PROBE_RX__:nemu.local:10.0.2.2`、`__NEMU_DNS_PROBE_PASS__:dns-a`、`__NEMU_CHECK_PASS__:virtio-net-dns-a`、`__NEMU_ICMP_PROBE_PASS__:icmp-echo`、TX/RX packets `5/5`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0` 和 `HIT GOOD TRAP`。`perf.tsv` 为 `boot_seconds=93`、`guest_check_seconds=260`、`poweroff_seconds=8`、`total_seconds=361`。
- `remaining_boundary`: 这不是 TAP/NAT/外网收发、通用递归 DNS、真实 host packet backend、network stress、control virtqueue/multiqueue、SMP、snapshot/GDB/monitor、完整 TB cache 或 DBT/JIT；它只闭合当前 hostless DNS A 记录切片。
