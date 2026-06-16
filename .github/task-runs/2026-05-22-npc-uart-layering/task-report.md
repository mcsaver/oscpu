# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-uart-layering`
- `task_slug`: `npc-uart-layering`
- `graph_template`: `am-device-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: uart 模块应该是单独的，然后接入到 AXI 中，而不是 axiuart
- `goal`: 把初始合体式 UART AXI slave 拆成独立 `Uart` 设备核心和 `AxiLiteToUart` AXI-Lite 适配层
- `scope`: `npc/single/vsrc/bus`、`NpcSimTop`、RTL filelist、模块 testbench、README 与 memory 记录

## RTL 推导摘要

- 需求要点：`Uart` 不直接暴露 AXI 信号，只表达寄存器读写和 TX/access 事件；crossbar 仍连接 AXI-Lite slave，因此新增适配层承接总线协议。
- 协议规则：native UART 侧读写都是单拍 valid；读数据组合返回；TX side effect 只在 native write valid 那拍产生。AXI 侧保持 single-beat valid-ready 语义，响应在 ready 前保持。
- 状态机骨架：`Uart` 当前无内部时序状态；`AxiLiteToUart` 读通道为 `IDLE/RVALID`，写通道保留 `aw_seen/w_seen/bvalid`，AW/W 齐备后只发起一次 native write。
- 关键不变量：一次 AXI 写最多转换成一次 UART native write；只有 offset 0 且 `WSTRB[0]` 有效才产生 TX；UART core 不依赖 AXI 信号名；crossbar 地址窗口仍是 `0x1000_0000..0x1000_0fff`。
- 数据通路骨架：AXI adapter 取 AXI 地址低 12 位作为 UART register offset，把完整 `WDATA/WSTRB` 传给 `Uart`；顶层实例名使用 `u_uart_axi`，适配层内部实例化 `u_uart`。

## 关键产物

- `artifacts`: `Uart.v`、`AxiLiteToUart.v`、`tb_uart.sv`、`tb_axi_lite_to_uart.sv`
- `removed_or_replaced`: 初始合体式 `AxiUartLite.v` 与 `tb_axi_uart_lite.sv`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 验证摘要

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-uart-layer-tests run`: 24/24 PASS
- `make -C npc/single lint`: PASS
- `make -C npc/single -j14`: PASS
- `./npc/single/build/NpcSimTop /tmp/npc-uartip.bin --no-progress --max-cycles 2000`: 输出 `X`，GOOD TRAP at `0x80000010`
- `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-uart-layer-pipe pipe_test`: PASS，load-hit/frontend-hit 可移除气泡仍为 0
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 当前本地 `NpcSimTop` 欢迎信息显示 Difftest OFF，本轮未覆盖 diff-on 回归
- `risk_assessment`: UART 仍是最小 TX/status 设备核心，不是完整 16550；AXI 适配层当前只覆盖 single-beat AXI-Lite 访问

## 收尾结论

- `final_result`: UART 已拆成独立设备核心并通过 `AxiLiteToUart` 接入 crossbar，地址窗口仍为 `0x1000_0000..0x1000_0fff`
- `evidence_summary`: native UART 单测、AXI 适配层单测、lint/build、top 级 UART smoke、pipe_test 和 cpu-tests 均通过
