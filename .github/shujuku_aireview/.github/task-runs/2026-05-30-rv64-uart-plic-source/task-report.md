# Task Report

## 基本信息

- `task_id`: `2026-05-30-rv64-uart-plic-source`
- `task_slug`: `rv64-uart-plic-source`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-30 21:45 +0800`
- `updated_at`: `2026-05-30 21:54 +0800`

## 任务目标

- `source_request`: 继续完成 RV64 core Linux boot 前置能力，不能把 PLIC pending 人工注入当成完整平台外部中断。
- `goal`: 将 PLIC source 1 接到真实 UART interrupt source，并用 mini boot 测试覆盖 UART -> PLIC -> S-mode trap。
- `scope`: `npc/rv64` UART RTL、AXI adapter、PLIC gateway、仿真顶层接线、focused testbench、`am-kernels` cpu-test、memory/task-run 记录。

## RTL 推导摘要

- `需求`: UART 增加最小 16550-style `IER/IIR/LSR` 与 `irq_o`，RV64 aligned MMIO 读能返回 byte offset 5 的 LSR；PLIC source 1 接 UART IRQ；新增真实设备源的 S-mode external interrupt mini boot。
- `协议规则`: UART native register access 仍由 AXI adapter 在 AR fire/write_done 当拍发起；写按 `WSTRB` lane 更新 byte register；`IER[1]` 使能 THRE interrupt；`IIR` read 返回 THRE pending 并清 pending。PLIC claim read 清 pending 并进入 in-service，completion write source id 1 后退出。
- `状态机`: UART 维护 `ier/lcr/thre_pending`，reset 清零；写 `IER[1]` 或 THR 更新 THRE pending，读 IIR 清 pending。PLIC 维护 `pending/in_service`，source 置 pending，claim 进入 in-service，completion 返回可重新接收 source。
- `不变量`: `external_irq` 只由 `pending && enable && priority>threshold` 产生；in-service 期间 level source 不重复置 pending；UART read data 必须按 beat lane 组装，不能只在 offset `+4` 返回 LSR；R/B valid payload 稳定性由原 AXI adapter 保持。
- `数据通路`: UART byte register mux 按 `reg_read_addr_i + lane` 生成 `DATA_W`；write loop 按 lane 解释 offset0 THR、offset1 IER、offset2 FCR、offset3 LCR；PLIC completion 支持低 32-bit exact claim 与 RV64 aligned high-lane claim。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `inspect-platform-gap` | Codex | completed | memory/source grep | 选定 UART->PLIC source 缺口 | PLIC source 原先仍无真实设备源 |
| `rtl-uart-irq` | Codex | completed | `Uart.v`, `AxiLiteToUart.v` | `IER/IIR/LSR/irq_o` | `tb_uart`, `tb_axi_lite_to_uart` PASS |
| `rtl-plic-gateway` | Codex | completed | `AxiLitePlic.v` | `in_service_q`, completion re-pend | `tb_axi_lite_plic` PASS |
| `wire-top` | Codex | completed | `NpcSimTop.sv` | UART IRQ 接 PLIC source 1 | rv64 lint/build PASS |
| `mini-boot-test` | Codex | completed | `am-kernels/tests/cpu-tests` | `uart-plic-sirq.c` | `uart-plic-sirq` PASS |
| `regression` | Codex | completed | focused tests | 8 项 focused + smoke | focused 8/8, `plic-sirq`, `add` PASS |

## 关键产物

- `artifacts`: `npc/rv64/vsrc/bus/Uart.v`, `npc/rv64/vsrc/bus/AxiLiteToUart.v`, `npc/rv64/vsrc/bus/AxiLitePlic.v`, `npc/rv64/vsrc/sim/NpcSimTop.sv`, `am-kernels/tests/cpu-tests/tests/uart-plic-sirq.c`
- `logs_or_traces`: `/tmp/rv64-uart-plic-focused`; `uart-plic-sirq` run 输出 `cycles=458/commits=115`; `add` run 输出 `CPI=0.900`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/modules/am-kernels.md`, `.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: 无阻塞本轮 focused 目标。
- `missing_dependencies`: 完整 Linux boot 仍缺 virtio/blk、DTB、真实 kernel/OpenSBI 镜像加载、多 source PLIC 与完整 SBI 服务。
- `risk_assessment`: UART/PLIC 仍是 mini model；UART 无 RX FIFO/真实输入，PLIC 单源且 aligned threshold/claim side effect 仍有简化。

## 下一步建议

1. 实现 virtio-mmio 或项目既有块设备路径的最小 register/queue smoke，并接入 PLIC source。
2. 增加 DTB/boot image 加载路径或构造更接近 OpenSBI/Linux early boot 的 payload。

## 模板升级候选

- `repeated_dynamic_subgraph`: platform source -> interrupt controller -> S-mode mini boot -> focused regression
- `should_promote_to_static_template`: `maybe`
- `reason`: 后续 virtio/blk、timer/SBI 服务会复用同一跨层验证套路。

## 收尾结论

- `final_result`: 已把 PLIC source 1 接到真实 UART THRE interrupt，并用 `uart-plic-sirq` 证明 UART -> PLIC -> S-mode external interrupt 链路。
- `evidence_summary`: focused 8/8 PASS；rv64 lint/build PASS；`uart-plic-sirq` PASS；`plic-sirq` PASS；`add` PASS；`git diff --check` PASS。
- `notes`: 仍不宣称真实 Linux 已启动。
