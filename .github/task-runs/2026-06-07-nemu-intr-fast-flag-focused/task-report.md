# Task Report

## 基本信息

- `task_id`: 2026-06-07-nemu-intr-fast-flag-focused
- `task_slug`: nemu-intr-fast-flag-focused
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-07 11:28:36 +0800
- `updated_at`: 2026-06-07 11:34:05 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-focused-gate` | `nemu` | `nemu` | `PASS` | optional focused Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行真实 guest gate，否则 SKIP | .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence/nemu-ubuntu-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused
- `logs_or_traces`: .github/task-runs/2026-06-07-nemu-intr-fast-flag-focused/evidence
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

## 本轮切片说明

- `implemented_slice`: NEMU Ubuntu performance 配置新增 `CONFIG_INTERPRETER_INTR_FAST_FLAG`。`cpu-exec.c` 在 TB 边界进入完整 `isa_query_intr()` 前，先调用 `isa_riscv32_intr_pending_fast()` 做保守 pending/enable/global 判断；确定没有可投递中断时直接跳过完整 CLINT/PLIC pending 计算。
- `semantic_boundary`: fast flag 只使用 CSR `mie/mstatus/priv`、CLINT `mtime/msip/host_timer` 与 PLIC raw pending+enable 的轻量条件判断；只要存在任何可能可投递中断，就回到旧 `isa_query_intr()` 路径决定最终 cause 和清除 host timer pending。该切片不改变 CLINT/PLIC/CSR 语义，不移动中断投递边界，也不替代异步设备模型。
- `e2e_contract`: `nemu-ubuntu` contract 已要求 `CONFIG_INTERPRETER_INTR_FAST_FLAG=y`、`check-nemu-performance-config.sh CONFIG_INTERPRETER_INTR_FAST_FLAG`、`cpu/Kconfig config INTERPRETER_INTR_FAST_FLAG`，并检查 `cpu-exec.c isa_riscv32_intr_pending_fast`、`riscv64/system/intr.c isa_riscv32_intr_pending_fast`、`riscv64/system/plic.c isa_riscv32_plic_maybe_pending` 与 `isa.h isa_riscv32_intr_pending_fast` hook。
- `focused_evidence`: 真实 focused guest gate PASS，`perf.tsv` 为 `boot=91s / guest_check=228s / poweroff=8s / total=327s`。
- `guest_markers`: console 覆盖 systemd running、failed count 0、ttyS0 write、virtio-rng、goldfish-rtc、virtio-blk blk-size/flush/topology/config-wce/discard/write-zeroes feature gates、vda discard/write-zeroes/cache、IRQ serial/virtio-blk、syscon poweroff 与 `HIT GOOD TRAP`；坏模式扫描未发现 `__NEMU_CHECK_FAIL__`、`HIT BAD TRAP`、kernel panic、BUG、Oops 或 Call Trace。
- `remaining_scope`: 总目标仍未完成；剩余包括完整 TB/decode cache、物理代码页失效和 self-modifying tracking、异步 virtio-blk、多队列、virtio-net、SMP、snapshot/GDB/monitor API、PCI/更多 virtio transport、长期压力和 DBT/JIT。单轮 focused gate 的耗时改善只作为当前门禁趋势证据，不作为正式多工作负载性能基准。
