# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-rv64-inst-organization-contract
- `task_slug`: nemu-rv64-inst-organization-contract
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-11 03:14:30 +0800
- `updated_at`: 2026-06-11 03:14:50 +0800

## 任务目标

- `source_request`: 继续优化 NEMU 启动完整 Ubuntu 22.04，并把 RV64 `inst.c` 拆分后的组织边界纳入 e2e 防回归闭环
- `goal`: 验证 `nemu-ubuntu` profile 中新增的 RV64 inst 组织层 contract，生成可复核证据包
- `scope`: profile=nemu-ubuntu；只证明低成本源码组织/命名边界和既有静态 gate，不越级声明 full focused guest、QEMU 等价或长期 soak 已完成

## 选图说明

- `selected_template`: modular-agent-e2e
- `why_this_graph`: 本 profile 从 `.github/e2e/profiles/` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | agent-env + bash/git/make/python/gcc/verilator/toolchain | 非交互软环境、hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/rv64-linux-contract.log |
| `software-flow-contract` | `software-flow` | `software-flow` | `PASS` | software-flow agent + profile + memory | 软件开发全流程 agent 合约入口存在 | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/software-flow-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence/nemu-ubuntu-slice-contract.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract
- `logs_or_traces`: .github/task-runs/2026-06-11-nemu-rv64-inst-organization-contract/evidence
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

- `final_result`: profile=nemu-ubuntu 通过，新增 RV64 `inst.c` 组织层防漂移 gate 已执行。
- `evidence_summary`: `nemu-ubuntu-slice-contract.log` 含顶层行数、顶层只 orchestration、10 个 fragment include 和全量 fragment coverage PASS。
- `notes`: 这是模块化 e2e gate，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate、full focused guest、QEMU 等价或 PPA/STA signoff。
