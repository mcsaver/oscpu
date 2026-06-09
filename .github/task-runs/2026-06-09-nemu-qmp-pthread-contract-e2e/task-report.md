# Task Report

## 基本信息

- `task_id`: 2026-06-09-nemu-qmp-pthread-contract-e2e
- `task_slug`: nemu-qmp-pthread-contract-e2e
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-09 13:50:45 +0800
- `updated_at`: 2026-06-09 13:50:50 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence/nemu-ubuntu-slice-contract.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e
- `logs_or_traces`: .github/task-runs/2026-06-09-nemu-qmp-pthread-contract-e2e/evidence
- `profile_manifest`: .github/e2e/profiles/nemu-ubuntu.tsv
- `linked_memory_updates`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

## 本轮追加摘要

- `change`: 将 QMP runtime 线程的 native 构建规则纳入 `nemu-ubuntu` slice contract。
- `why`: `qmp.c` 在 `cont` 后会启动后台 runtime client 线程，完成判定不能只看源码 hook 和 runtime smoke，还要检查 `nemu/src/filelist.mk` 是否保留 pthread 编译/链接参数。
- `evidence`: `evidence/nemu-ubuntu-slice-contract.log` 含 `PASS src/filelist.mk CFLAGS += -pthread` 与 `PASS src/filelist.mk LIBS += -pthread`；`evidence/nemu-ubuntu-static.log` 仍含 QMP runtime-query smoke PASS。
- `summary`: `evidence/nemu-qmp-pthread-contract-summary.log`
- `boundary`: 该切片只证明 QMP runtime 线程构建/e2e 追踪闭合，不代表完整 QMP schema、events、pause/resume、blockdev、migration、SMP/PCI 或完整 Ubuntu 22.04。

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
