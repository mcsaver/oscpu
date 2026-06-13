# Task Report

## 基本信息

- `task_id`: `2026-05-30-rv64-plic-sirq`
- `task_slug`: `rv64-plic-sirq`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-30 20:40 +0800`
- `updated_at`: `2026-05-30 21:41 +0800`

## 任务目标

- `source_request`: 继续推进 `npc/rv64` 可启动 Linux 的指令/特权/平台能力，并在 WSL 崩溃归因后继续做可验证的前置闭环。
- `goal`: 增加最小 PLIC-like 平台中断设备，让真实 `NpcSimTop` 能通过 S-mode external interrupt mini boot 测试。
- `scope`: `npc/rv64` AXI-Lite PLIC RTL、仿真顶层地址图/IRQ 接线、focused testbench、`am-kernels` cpu-test、memory/task-run 记录。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 任务跨 RTL bus/top、privilege trap、AM 测试与项目记忆，现有固定模板不能完全表达平台设备逐步闭合。
- `dynamic_nodes_added`: `rtl-derive-plic`, `wire-platform`, `unit-test-plic`, `mini-boot-plic-sirq`, `memory-record`
- `why_dynamic_nodes_were_needed`: PLIC 不是单指令修复，需要先推导协议和 side effect，再接入顶层和端到端测试。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `rtl-derive-plic` | Codex | completed | Linux boot external IRQ 缺口、当前 AXI-Lite/LSU lane 规则 | 单 source M/S context PLIC-like 寄存器模型 | 四阶段 RTL 推导记录于对话；实现落在 `AxiLitePlic.v` |
| `wire-platform` | Codex | completed | `NpcSimTop` bus slave table、`define.v` 地址宏 | PLIC 地址窗口 `0x0c00_0000`，external IRQ 接 core | rv64 lint PASS |
| `unit-test-plic` | Codex | completed | PLIC AXI-Lite RTL | `tb_axi_lite_plic` | focused 6/6 PASS |
| `mini-boot-plic-sirq` | Codex | completed | `plic-sirq.c` | S-mode PLIC config、pending 注入、WFI trap、claim/complete | `plic-sirq` PASS，`cycles=399/commits=98` |
| `regression-smoke` | Codex | completed | rv64 build/lint/add | lint/build/add smoke | `add` PASS，`cycles=755/commits=839/CPI=0.900` |
| `memory-record` | Codex | completed | 修改与验证结果 | project/modules/known-issues/task-run 更新 | 本目录与 `.github/memory/*` |

## 关键产物

- `artifacts`: `npc/rv64/vsrc/bus/AxiLitePlic.v`, `npc/rv64/testbench/tests/tb_axi_lite_plic.sv`, `am-kernels/tests/cpu-tests/tests/plic-sirq.c`
- `logs_or_traces`: `/tmp/rv64-plic-focused2` focused testbench result；`NpcSimTop` run 输出 `plic-sirq PASS` 和 `add PASS`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/modules/am-kernels.md`, `.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: 无阻塞本轮 focused 目标。
- `missing_dependencies`: 完整 Linux boot 仍缺真实多源 PLIC/外设 source、virtio/blk、DTB、真实 kernel/OpenSBI 镜像加载与更完整 SBI 服务模型。
- `risk_assessment`: 当前 PLIC 是 mini boot 单源模型；aligned threshold/claim 共 beat 读存在 side effect 简化，后续做通用 PLIC ABI 前必须重新收口。

## 下一步建议

1. 将 PLIC `source_irq_i` 接入真实 UART/virtio 或仿真设备 source，并补多 source/gateway/claim priority。
2. 增加 DTB/virtio/blk/SBI 服务测试，形成接近真实 Linux early boot 的端到端镜像验证。

## 模板升级候选

- `repeated_dynamic_subgraph`: Linux boot 前置平台设备闭合：RTL 推导 -> 顶层接线 -> focused MMIO 单测 -> AM mini boot -> memory 记录。
- `should_promote_to_static_template`: `maybe`
- `reason`: 后续 virtio/DTB/SBI 也会重复类似跨层流程，可沉淀为 `rv64-linux-platform-loop`。

## 收尾结论

- `final_result`: 已新增最小 PLIC-like 设备并通过 unit/focused/真实 cpu-test 验证 S-mode external interrupt mini boot 路径。
- `evidence_summary`: focused `tb_axi_lite_plic tb_axi_lite_clint tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_int_backend` 6/6 PASS；rv64 lint PASS；rv64 build PASS；`plic-sirq` PASS；`add` PASS。
- `notes`: 本轮继续推进 Linux boot 前置闭环，但没有宣称真实 Linux 已启动。
