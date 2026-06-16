# Task Report

## 基本信息

- `task_id`: 2026-06-06-nemu-interpreter-tb-focused
- `task_slug`: nemu-interpreter-tb-focused
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-06 23:34:44 +0800
- `updated_at`: 2026-06-06 23:44:56 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-focused-gate` | `nemu` | `nemu` | `PASS` | optional focused Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行真实 guest gate，否则 SKIP | .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence/nemu-ubuntu-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-06-nemu-interpreter-tb-focused
- `logs_or_traces`: .github/task-runs/2026-06-06-nemu-interpreter-tb-focused/evidence
- `profile_manifest`: .github/e2e/profiles/nemu-ubuntu-gate.tsv
- `linked_memory_updates`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 见对应 tool/env 节点日志
- `risk_assessment`: 无 hard fail；optional tool 缺失只作为后续节点风险。

## 本轮切片说明

- `implemented_slice`: 上传路线图阶段 B 的 basic block interpreter 第一阶段。NEMU Ubuntu performance 配置新增 `CONFIG_INTERPRETER_BASIC_BLOCK=y`；解释器在普通连续指令上走保守 `execute_basic_block()`，最多 16 条为一块，减少每条指令都执行 `isa_query_intr()` 与 `device_update()` 的主循环开销。
- `semantic_boundary`: TB 遇到 branch/jump、SYSTEM/CSR/WFI/sret/mret/sfence.vma、fence、store/AMO 或压缩控制/存储指令立即收束；WFI 后 timer interrupt、CSR 重新开中断、CLINT/PLIC/virtio/UART MMIO store 后的中断可见性仍在下一块入口重新观察。`device_update_after_inst(retired)` 按退休 guest 指令数累计，保持原 64 指令节流口径。
- `e2e_contract`: `nemu-ubuntu` slice contract 已要求 `INTERPRETER_TB_MAX_INST`、`execute_basic_block`、`interpreter_tb_should_stop`、`device_update_after_inst(retired`、`config INTERPRETER_BASIC_BLOCK`、`CONFIG_INTERPRETER_BASIC_BLOCK=y`，并将 `check-nemu-performance-config.sh` 收紧为实际 `.config/autoconf.h` 必须启用 `CONFIG_INTERPRETER_BASIC_BLOCK`。
- `focused_evidence`: `.github/task-runs/2026-06-06-nemu-interpreter-tb-focused/nemu-ubuntu-focused/perf.tsv` 记录 `boot=165s/guest_check=431s/poweroff=14s/total=610s`，参数为 `soak=0`、`fs_stress_mib=1`、`fs_tree_files=8`、`process_loops=4`、`uart_rx_stress_lines=64`、`block_parallel_jobs=1`、`block_job_mib=1`、`max_cycles=25000000000`。
- `guest_markers`: console 覆盖 systemd running、serial-getty@ttyS0、ttyS0 write、virtio-rng/hwrng、goldfish-rtc、virtio-blk queue/feature gates、IRQ serial/virtio-blk 增长、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`、syscon poweroff 和 `HIT GOOD TRAP`；坏模式扫描未发现 `__NEMU_CHECK_FAIL__`、`HIT BAD TRAP`、`Kernel panic`、`BUG:`、`Oops` 或 `Call Trace`。
- `performance_note`: 与上一轮 iTLB/dTLB focused gate `235/610/20/865s` 相比，本轮同类 focused gate 降到 `165/431/14/610s`；该对比证明当前门禁场景下有明显改善，但仍不是跨多轮、多工作负载的正式性能基准。
- `remaining_scope`: 尚未实现 decode cache、代码页失效/self-modifying tracking、异步或批处理 virtio-blk I/O、多队列、virtio-net、SMP、snapshot/GDB/monitor API、DBT/JIT 或 QEMU 级通用 VM 能力。

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
