# Task Report

## 基本信息

- `task_id`: 2026-06-11-github-index-chunk-memory-contracts
- `task_slug`: github-index-chunk-memory-contracts
- `graph_template`: modular-agent-e2e
- `profile`: contracts
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-11 16:32:21 +0800
- `updated_at`: 2026-06-11 16:33:42 +0800

## 任务目标

- `source_request`: 把大量 Markdown 变成可查询、可压缩、可按需加载的开发记忆系统
- `goal`: 在 `github-index` chunk/summary/load 改动后执行全局低成本 contract 回归，确认规则入口与模块合约未漂移
- `scope`: profile=contracts；本切片只证明低成本 agent/module 合约和 `github-index` 记忆加载入口通过，不越级声明完整长期记忆系统整体完成

## 选图说明

- `selected_template`: modular-agent-e2e
- `why_this_graph`: 本 profile 从 `.github/e2e/profiles/` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | agent-env + bash/git/make/python/gcc/verilator/toolchain | 非交互软环境、hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/npc-sim-status.log |
| `profile-index` | `agent-system` | `agent-system` | `PASS` | .github/e2e/profiles | 列出所有可执行 profile | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/profile-index.log |
| `ysyx-coordinator-contract` | `ysyx-coordinator` | `ysyx-coordinator` | `PASS` | coordinator agent + blueprint + profile root | 总调度 e2e 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/ysyx-coordinator-contract.log |
| `hardware-flow-contract` | `hardware-flow` | `hardware-flow` | `PASS` | hardware-flow agent + scripts/am-regression.sh + e2e profiles | 硬件流程合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/hardware-flow-contract.log |
| `software-flow-contract` | `software-flow` | `software-flow` | `PASS` | software-flow agent + profile + memory | 软件开发全流程 agent 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/software-flow-contract.log |
| `github-index-contract` | `agent-system` | `github-index` | `PASS` | scripts/github_index_db.py + .github files | .github SQLite 索引数据库入口可构建、查询和巡检 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/github-index-contract.log |
| `abstract-machine-contract` | `abstract-machine` | `abstract-machine` | `PASS` | AM Makefile/scripts/include/memory | AM 平台合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/abstract-machine-contract.log |
| `am-kernels-contract` | `am-kernels` | `am-kernels` | `PASS` | cpu-tests/am-tests/klib-tests/benchmarks | 测试与 benchmark 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/am-kernels-contract.log |
| `nemu-config-probe` | `nemu` | `nemu` | `PASS` | nemu Kconfig/configs/device filelist | NEMU 当前配置和参考入口可见 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/nemu-config-probe.log |
| `npc-sim-contract` | `npc` | `npc` | `PASS` | npc/sim + backends | NPC 统一仿真入口合约存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/npc-sim-contract.log |
| `npc-single-contract` | `npc` | `npc` | `PASS` | npc/single Makefile/Kconfig/vsrc/csrc | NPC single 后端合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/npc-single-contract.log |
| `npc-soc-contract` | `npc` | `npc` | `PASS` | npc/soc + ysyxSoC CPU ABI | NPC SoC 后端合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/npc-soc-contract.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/npc-rv64-contract.log |
| `ysyx-soc-contract` | `ysyx-soc` | `ysyx-soc` | `PASS` | ysyxSoC Makefile/spec/agent/memory | ysyxSoC 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/ysyx-soc-contract.log |
| `difftest-contract` | `difftest` | `difftest` | `PASS` | NEMU spike-diff + npc/sim difftest-ref | DiffTest 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/difftest-contract.log |
| `yosys-sta-contract` | `yosys-sta` | `yosys-sta` | `PASS` | yosys-sta Makefile/tools/memory | 综合/STA 合约入口和工具状态可见 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/yosys-sta-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/rv64-linux-contract.log |
| `linux-device-contract` | `linux-device` | `linux-device` | `PASS` | virtio-rootfs instruction + Linux scripts | Linux 设备合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/linux-device-contract.log |
| `display-vga-contract` | `display-vga` | `display-vga` | `PASS` | linux-framebuffer-vga instruction + Linux README | 显示/fbcon 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/display-vga-contract.log |
| `verilator-tapeout-contract` | `verilator-tapeout` | `verilator-tapeout` | `PASS` | verilator realism instruction + npc/rv64 | Verilator-first 流片边界合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/verilator-tapeout-contract.log |
| `fceux-am-contract` | `fceux-am` | `fceux-am` | `PASS` | fceux-am Makefile/agent/memory | FCEUX-AM 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/fceux-am-contract.log |
| `nvboard-contract` | `nvboard` | `nvboard` | `PASS` | nvboard README/scripts/example/agent | NVBoard 合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/nvboard-contract.log |
| `digital-logic-contract` | `digital-logic` | `digital-logic` | `PASS` | digital_logic_experiment + agent | 数字逻辑实验合约入口存在 | .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence/digital-logic-contract.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-11-github-index-chunk-memory-contracts
- `logs_or_traces`: .github/task-runs/2026-06-11-github-index-chunk-memory-contracts/evidence
- `profile_manifest`: .github/e2e/profiles/contracts.tsv
- `linked_memory_updates`: .github/memory/project-status.md, .github/memory/modules/agent-system.md

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

- `final_result`: profile=contracts 通过，`github-index-contract` 与其它低成本模块合约在 chunk/summary/load 改动后仍可执行。
- `evidence_summary`: `github-index-contract.log` 含 chunk interface PASS、`summary=.github/memory ... chunks=... token_estimate=...`、`load=software-flow mode=chunk-fts`；节点表中 25 个 contract 节点均为 PASS。
- `notes`: 这是全局低成本 contract 回归，不替代未执行模块的功能回归、DiffTest、Linux/Ubuntu 分层 gate 或 PPA/STA signoff。
