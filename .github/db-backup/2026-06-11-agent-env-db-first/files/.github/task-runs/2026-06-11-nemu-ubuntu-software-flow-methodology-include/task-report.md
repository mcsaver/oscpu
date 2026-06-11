# Task Report

## 基本信息

- `task_id`: 2026-06-11-nemu-ubuntu-software-flow-methodology-include
- `task_slug`: nemu-ubuntu-software-flow-methodology-include
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-11 14:17:10 +0800
- `updated_at`: 2026-06-11 14:17:30 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | agent-env + bash/git/make/python/gcc/verilator/toolchain | 非交互软环境、hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/rv64-linux-contract.log |
| `software-flow-contract` | `software-flow` | `software-flow` | `PASS` | software-flow agent + profile + memory | 软件开发全流程 agent 合约入口存在 | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/software-flow-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence/nemu-ubuntu-slice-contract.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include
- `logs_or_traces`: .github/task-runs/2026-06-11-nemu-ubuntu-software-flow-methodology-include/evidence
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

- `final_result`: profile=nemu-ubuntu 通过；NEMU Ubuntu 主生产守门现在显式检查 soft-flow include 与方法论守门没有被摘除。
- `evidence_summary`: `evidence/nemu-ubuntu-slice-contract.log` 含 `PASS nemu-ubuntu profile keeps software-flow include`、`PASS software-flow profile exposes software-flow-contract`，以及 `software-dev-loop`、`software-bugfix-loop`、`hardware-aware-software-loop`、hardware-aware 节点序列和反假完成约束的 `PASS software-flow methodology available to nemu-ubuntu ...` marker。
- `negative_scan`: 对本 task-run 窄扫描 `^FAIL ` 与 `__NEMU_CHECK_FAIL__` 无命中；宽扫 `ERROR` 只命中预期错误分类 marker 的 PASS 行，不作为失败。
- `notes`: 这是 NEMU Ubuntu 主链路的软件开发方法论防漂移 gate，不替代 full focused guest、full soak、DiffTest、Linux/Ubuntu 分层 gate、NPC/RTL target、PPA/STA 或完整 Ubuntu/QEMU 等价证明。
