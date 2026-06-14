# Task Report

## 基本信息

- `task_id`: `2026-05-31-rv64-uart-thre-level`
- `task_slug`: `rv64-uart-thre-level`
- `graph_template`: `rv64-ubuntu-probe-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-31`
- `updated_at`: `2026-05-31`

## 任务目标

- `source_request`: 用户要求以完整 Ubuntu 22.04/Linux bring-up 为目标，暂不以 Vivado 为前置，使用 Verilator 做尽量真实的性能/系统仿真，并先配置 agent 环境避免未来误判。
- `goal`: 把 NPC 上 Ubuntu probe `/init` 已执行但串口只显示 16 字节前缀的问题收窄并补一个真实设备语义改动。
- `scope`: `npc/rv64/vsrc/bus/Uart.v`、UART/PLIC focused testbench、相关 memory 和 task-run 记录。

## 选图说明

- `selected_template`: `rv64-ubuntu-probe-loop`
- `why_this_graph`: 当前证据层级是 NPC 已到 `init-executed`，下一步要把 UART 可见性补到可支撑 `ubuntu-probe-visible`。
- `dynamic_nodes_added`: `uart-thre-root-cause`、`uart-focused-rtl-fix`、`verilator-top-build`
- `why_dynamic_nodes_were_needed`: 静态图只描述 probe gate，未细分 Linux 8250/16550A 的 THRE refill 设备语义。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `env-recall` | `rv64-linux` | completed | AGENTS、rv64 Linux/Verilator instructions、project memory、用户上传文档 | 明确不越级声称完整 Ubuntu，当前 gate 仍是 `init-executed` | `.github/instructions/rv64-linux-bringup.instructions.md`、上传文档 |
| `uart-thre-root-cause` | `linux-device` | completed | NPC 日志 `[ysyx-init] Ubun`、Linux 8250 本地源码 | 16 字节截断与 `PORT_16550A tx_loadsz=16` 对齐，优先修 UART THRE refill 语义 | `npc/rv64/env/src/linux/drivers/tty/serial/8250/8250_port.c` |
| `uart-focused-rtl-fix` | `linux-device` | completed | `Uart.v`、`tb_uart`、`tb_axi_lite_to_uart` | THRE level IRQ、DLAB、FCR/IIR FIFO 位；focused tests 更新 | `tb_uart` PASS、`tb_axi_lite_to_uart` PASS |
| `plic-regression` | `linux-device` | completed | `AxiLitePlic` focused test | 单源 level source complete 后 repend 仍 PASS | `tb_axi_lite_plic` PASS |
| `verilator-top-build` | `verilator-tapeout` | completed | rv64 Verilator top | 顶层二进制可重编译 | `make -C npc/rv64 default` PASS |
| `record` | `ysyx-coordinator` | completed | 代码改动、验证结果 | memory/task-run 已更新 | `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md` |

## 关键产物

- `artifacts`: `npc/rv64/vsrc/bus/Uart.v`、`npc/rv64/testbench/tests/tb_uart.sv`、`npc/rv64/testbench/tests/tb_axi_lite_to_uart.sv`
- `logs_or_traces`: `/tmp/ysyx-rv64-uart-thre2/logs/tb_uart.log`、`/tmp/ysyx-rv64-uart-thre2/logs/tb_axi_lite_to_uart.log`、`/tmp/ysyx-rv64-uart-thre2/logs/tb_axi_lite_plic.log`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: 未跑完整 `smoke-ubuntu-initramfs` 长仿真，不能确认 `/etc/os-release` 在 NPC stdout 中完整可见。
- `missing_dependencies`: 后续完整 Ubuntu shell/rootfs 仍缺完整 F/D、virtio-blk、多源 PLIC、UART RX/输入和 rootfs 设备闭环。
- `risk_assessment`: THRE 现在按当前零延迟 TX 模型做 level interrupt，适合 Verilator bring-up；若后续加入真实 FIFO/baud，应把 THRE level 条件改为 FIFO occupancy/empty 驱动，并保留 Linux 8250 focused 回归。

## 下一步建议

1. 用更新后的 Verilator 二进制重跑可承受的 `smoke-ubuntu-initramfs`，目标是看到完整 `[ysyx-init]` 与 Ubuntu `/etc/os-release`。
2. 若仍截断，打开 UART/PLIC/SEIP 的低噪声 trace，区分是 PLIC complete/repend、core repeated external IRQ，还是 Linux tty write path 仍在等待。

## 模板升级候选

- `repeated_dynamic_subgraph`: `uart-thre-root-cause -> focused-rtl-fix -> verilator-top-build -> ubuntu-probe-rerun`
- `should_promote_to_static_template`: `false`
- `reason`: 当前是 `rv64-ubuntu-probe-loop` 下的设备子问题，暂不需要独立静态图。

## 收尾结论

- `final_result`: 已补强 UART 的 16550A THRE/FCR/DLAB 行为，并通过 focused module tests 和 Verilator 顶层编译。
- `evidence_summary`: `tb_uart` PASS；`tb_axi_lite_to_uart` PASS；`tb_axi_lite_plic` PASS；`make -C npc/rv64 default` PASS；`git diff --check` PASS。
- `notes`: 当前仍只能说为 `ubuntu-probe-visible` 清除一个高概率设备 blocker；没有完整长跑证据前，不把目标升级为完整 Ubuntu probe 可见。
