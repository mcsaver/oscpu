# Task Report

## 基本信息

- `task_id`: 2026-06-06-nemu-itlb-dtlb-split-focused
- `task_slug`: nemu-itlb-dtlb-split-focused
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu-gate
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-06 23:04:35 +0800
- `updated_at`: 2026-06-06 23:19:01 +0800

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
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/nemu-ubuntu-slice-contract.log |
| `nemu-ubuntu-focused-gate` | `nemu` | `nemu` | `PASS` | optional focused Ubuntu rootfs/systemd guest gate | AGENT_E2E_NEMU_UBUNTU_GATE=1 时运行真实 guest gate，否则 SKIP | .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence/nemu-ubuntu-focused-gate.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused
- `logs_or_traces`: .github/task-runs/2026-06-06-nemu-itlb-dtlb-split-focused/evidence
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

- `implemented_slice`: 上传路线图阶段 B 的 iTLB/dTLB 分离切片。`nemu/src/isa/riscv64/system/mmu.c` 将原单个 `sv39_tlb[]` 拆为 `sv39_itlb[]` 和 `sv39_dtlb[]`，取指走 iTLB，load/store 走 dTLB。
- `semantic_boundary`: dTLB 内仍保留 READ/WRITE type key，避免把读权限和写权限缓存混用；`sfence.vma` 与 `satp` 写仍全量 flush 两张表；host-page TLB 快路径、MMIO 回落、跨页 store 先翻译后写入的精确异常边界保持不变。
- `e2e_contract`: `scripts/e2e/modules/nemu.sh` 已把 `sv39_itlb`、`sv39_dtlb` 与 `sv39_tlb_set_for_type` 纳入 `nemu-ubuntu-slice-contract`；fast profile `2026-06-06-nemu-itlb-dtlb-split-e2e` PASS。
- `focused_evidence`: 本 profile 真实 `nemu-ubuntu-focused-gate` PASS，`perf.tsv` 为 `boot=235s/guest_check=610s/poweroff=20s/total=865s`；console marker 覆盖 ttyS0 write、virtio-rng、goldfish-rtc、virtio-blk feature gates、IRQ serial/virtio-blk、systemd rc=0、自然 poweroff 与 `HIT GOOD TRAP`，坏模式扫描为空。
- `performance_note`: 单次 focused run 只证明 iTLB/dTLB 分离切片兼容完整 guest gate；由于 guest_check 受 systemd 脚本和宿主抖动影响，不能单独作为已量化提速结论。
- `remaining_scope`: 完整阶段 B 仍缺 basic block interpreter、decode cache、TB 边界中断检查、异步/批处理 block I/O 和 DBT/JIT；阶段 C 仍缺 virtio-net、SMP、snapshot、monitor/GDB 等可用 VM 能力。
