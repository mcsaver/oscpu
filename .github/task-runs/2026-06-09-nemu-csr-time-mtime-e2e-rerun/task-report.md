# Task Report

## 基本信息

- `task_id`: 2026-06-09-nemu-csr-time-mtime-e2e-rerun
- `task_slug`: nemu-csr-time-mtime-e2e-rerun
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `graph_mode`: static
- `status`: blocked
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-09 02:12:26 +0800
- `updated_at`: 2026-06-09 02:12:27 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `FAIL` | recent NEMU Ubuntu device slice hooks and guest markers | exit=1 | .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence/nemu-ubuntu-slice-contract.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun
- `logs_or_traces`: .github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun/evidence
- `profile_manifest`: .github/e2e/profiles/nemu-ubuntu.tsv
- `linked_memory_updates`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

## 当前阻塞点

- `blockers`: 存在失败节点，详见 evidence 日志
- `missing_dependencies`: 见对应 tool/env 节点日志
- `risk_assessment`: 需要先查看 evidence 日志，按 regression-debug-loop 补 reproduce/collect/localize。

## 下一步建议

1. 修复失败节点或切换到更小 profile。
2. 对含 `SKIP` 的模块，先补依赖或切换到合适配置，再把该模块提升到 PASS 证据。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 已作为 modular-agent-e2e profile 固化
- `reason`: profile + module library + task-run 证据包能把 agent 提示转为可执行流水线

## 本轮补充

- `failure_root_cause`: 此次 rerun 的失败不是 NEMU time 功能失败，而是新增 `memtotal-before-uart-rx-stress` 顺序检查首版实现用普通 `grep -n`，误匹配了 `inject_uart_rx_stress_commands()` 函数内的占位符，导致 slice contract 假失败。
- `fix_forward`: 后续改为只在 `GUEST_CMDS` heredoc 之后用 `awk` 查找 `memtotal_kb=` 与 `__NEMU_UART_RX_STRESS_COMMANDS__`，避免匹配 host helper 函数。
- `superseded_by`: `.github/task-runs/2026-06-09-nemu-csr-time-mtime-e2e-rerun2/` 已验证修正后的静态 profile PASS。

## 收尾结论

- `final_result`: profile=nemu-ubuntu 存在失败节点；不能把后续工程判断建立在该节点上。
- `evidence_summary`: 详见节点表与 `evidence/`
- `notes`: 这是模块化 e2e gate，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate 或 PPA/STA signoff。
