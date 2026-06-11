# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-uartip`
- `task_slug`: `npc-uartip`
- `graph_template`: `am-device-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: 做一个 uartip，给 crossbar 控制，同时 UART 设备地址为 `0x1000_0000..0x1000_0fff`
- `goal`: 在 NPC AXI-Lite crossbar 后接入独立 UART RTL IP，并保留既有 PMEM/legacy MMIO 路径
- `scope`: `npc/single/vsrc`、`npc/single/csrc/dpi.c`、模块 testbench、README 与 memory 记录

## 选图说明

- `selected_template`: `am-device-loop`
- `why_this_graph`: 任务是新增 MMIO 设备并验证 AM/NPC 运行闭环
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | `.github/AGENTS.md`、copilot 指令、NPC memory、RTL/study 指令 | 明确 RTL 四段推导和记录要求 | 已读并按要求执行 |
| design | Codex | completed | `NpcAxiBus/AxiLiteXbar/AxiDpiSlave/NpcSimTop` | UART slave 地址表与协议设计 | 对话中已给 RTL 推导摘要 |
| implement | Codex | completed | 现有 AXI-Lite slave 协议 | `AxiUartLite`、crossbar 4 slave 接线、UART DPI event | 修改落盘 |
| verify | Codex | completed | lint/build/testbench/raw binary/cpu-tests | PASS 证据 | 见验证摘要 |
| record | Codex | completed | 改动与验证结果 | README、project-status、NPC module memory、本报告 | 本目录 |

## RTL 推导摘要

- 需求要点：新增 AXI-Lite single-beat UART slave，地址窗口 `0x1000_0000..0x1000_0fff`；写 offset 0 的 byte 输出字符；读 offset 4 返回 TX ready 与 16550 LSR 兼容状态；不实现 RX FIFO、真实波特率、中断或 DMA。
- 协议规则：使用现有 crossbar 的 `AR/R/AW/W/B` valid-ready；读在 AR 握手后保持 `RVALID` 到 `RREADY`；写允许 AW/W 分开到达，二者齐备后产生一次 `BVALID` 和最多一个 TX 脉冲；UART 响应 `OKAY`，未命中地址由 default slave 返回错误。
- 状态机骨架：读通道为 `IDLE/RVALID`；写通道用 `aw_seen/w_seen/bvalid` 表达，复位清空，AW/W 齐备后进入 B 响应，B 握手后回空闲。
- 关键不变量：`RVALID` 未握手前 payload 保持；一次完整写最多输出一个字符；只有 `write_addr[11:0]==0` 且 `WSTRB[0]` 有效才输出 TX；UART 地址窗口只由 crossbar `0xffff_f000` mask 命中。
- 数据通路骨架：`NpcSimTop` slave0 接 UART，slave1 接 PMEM DPI，slave2 接 legacy MMIO DPI，slave3 接 default error；UART 只用低 12 位地址、TX 低字节和 `WSTRB[0]`，顶层通过 `npc_uart_event()` 做仿真输出与 difftest skip。

## 关键产物

- `artifacts`: `AxiUartLite.v`、`tb_axi_uart_lite.sv`、`NpcSimTop` crossbar 地址表更新
- `logs_or_traces`: `/tmp/npc-uartip-tests2`、`/tmp/npc-uartip-pipe`、raw binary smoke 输出 `X` + GOOD TRAP
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 验证摘要

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-uartip-tests2 run`: 23/23 PASS
- `make -C npc/single lint`: PASS
- `make -C npc/single -j14`: PASS
- `./npc/single/build/NpcSimTop /tmp/npc-uartip.bin --no-progress --max-cycles 2000`: 输出 `X`，GOOD TRAP at `0x80000010`
- `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-uartip-pipe pipe_test`: PASS
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 当前本地 `NpcSimTop` 欢迎信息显示 Difftest OFF，本轮未覆盖 diff-on 回归
- `risk_assessment`: UART 只实现最小 TX/status 寄存器，不是完整 16550

## 收尾结论

- `final_result`: 已完成 crossbar 控制的 UART IP，地址窗口为 `0x1000_0000..0x1000_0fff`
- `evidence_summary`: lint/build/module/pipe/cpu-tests 与 raw UART smoke 均通过
- `notes`: 后续如要跑 Linux/RTOS 级 16550 driver，需要继续补 RX、IER/IIR/LCR/MCR 和中断语义
