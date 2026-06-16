# Task Report

## 基本信息

- `task_id`: 2026-06-08-nemu-virtio-net-icmp-focused-clean
- `task_slug`: nemu-virtio-net-icmp-focused-clean
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-08 22:59:35 +0800
- `updated_at`: 2026-06-08 23:05:46 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-focused-gate` | `nemu` | `nemu` | `PASS` | optional focused Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行真实 guest gate，否则 SKIP | .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence/nemu-ubuntu-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean
- `logs_or_traces`: .github/task-runs/2026-06-08-nemu-virtio-net-icmp-focused-clean/evidence
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

## 人工收口补充

- `slice_result`: NEMU virtio-net 已从 Linux 可枚举接口推进到 hostless `10.0.2.2` ARP/ICMP echo。guest 在 focused-clean 中配置 `eth0=10.0.2.15/24`，ICMP probe 看到 `__NEMU_ICMP_PROBE_TX__:10.0.2.2`、`__NEMU_ICMP_PROBE_RX__:10.0.2.2`、`__NEMU_ICMP_PROBE_PASS__:icmp-echo`，并通过 `__NEMU_CHECK_PASS__:virtio-net-icmp-echo`。
- `implementation_hooks`: `net.c` 保留 `VIRTIO_RING_F_INDIRECT_DESC`、`virtq_collect_table`、`VIRTIO_NET_F_MRG_RXBUF`、`VIRTIO_NET_RX_HDR_LEN`、`virtio_net_handle_arp`、`virtio_net_handle_icmp`、`virtio_net_try_deliver_rx_queue`；guest-check 保留 ICMP probe 编译/注入/执行与 TX/RX/route/neigh/ARP marker。
- `root_cause_history`: 中间失败依次定位出 focused gate 未硬拒 guest rc=1、probe 目录未提前创建、Linux TX 使用 12B vnet header、ARP/ICMP reply 需要最小 60B Ethernet frame、Linux RX 路径需要 12B header 与 `num_buffers=1`、virtio-net 描述符链使用 indirect descriptors。最终 clean run 已去掉临时 `__NEMU_NET_DEBUG__`。
- `focused_clean_evidence`: `__NEMU_CHECK_VIRTIO_NET_IPV4__:10.0.2.15/24`、`__NEMU_CHECK_VIRTIO_NET_ROUTE__:10.0.2.2 dev eth0 src 10.0.2.15 uid 0`、`__NEMU_CHECK_VIRTIO_NET_NEIGH__:10.0.2.2 lladdr 52:54:00:12:34:57 REACHABLE`、TX/RX packets `2/2`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、`HIT GOOD TRAP`，perf `boot=95s/guest_check=266s/poweroff=8s/total=369s`。
- `remaining_boundary`: 当前仅证明内置 hostless fake host 的最小二层/三层活性；仍未闭合 TAP/NAT/外网、真实 packet backend、control virtqueue/multiqueue、网络压力、SMP、snapshot/GDB/monitor、完整 TB cache 或 DBT/JIT。
