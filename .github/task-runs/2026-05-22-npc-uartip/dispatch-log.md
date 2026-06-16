# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-uartip`
- `task_slug`: `npc-uartip`
- `graph_template`: `am-device-loop`
- `log_policy`: `append-only`

---

### [2026-05-22 18:00] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求新增 UART IP 并接入 crossbar
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、project/memory、NPC study 与 RTL workflow
- `action`: 读取规则与现有总线/设备实现
- `outputs`: 确认必须执行 RTL 四段推导、验证和 memory/task-runs 记录
- `evidence`: 规则与源码阅读完成
- `next_step`: 设计 UART slave 与地址表

### [2026-05-22 18:10] `design` - `completed`

- `owner_agent`: Codex
- `trigger`: 需要在 RTL 修改前完成协议/状态机/不变量推导
- `depends_on`: `recall`
- `inputs`: `NpcAxiBus`、`AxiLiteXbar`、`AxiDpiSlave`、`NpcSimTop`
- `action`: 定义 UART 最小寄存器、AXI-Lite 握手、crossbar slave 顺序和地址 mask
- `outputs`: UART 映射 `0x1000_0000/0xffff_f000`，PMEM/legacy MMIO/default 三个保留路径
- `evidence`: 对话内 RTL 推导摘要
- `next_step`: 实现 RTL 与 DPI event

### [2026-05-22 18:25] `implement` - `completed`

- `owner_agent`: Codex
- `trigger`: 设计完成
- `depends_on`: `design`
- `inputs`: 现有 AXI-Lite slave 协议
- `action`: 新增 `AxiUartLite`，扩展 `NpcSimTop` 到 4 个 slave，新增 `npc_uart_event()`，补 `tb_axi_uart_lite`
- `outputs`: 代码落盘
- `evidence`: `git diff` 和后续验证
- `next_step`: 运行 lint/test/build

### [2026-05-22 18:40] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: 实现完成
- `depends_on`: `implement`
- `inputs`: testbench、Verilator、临时 raw binary、cpu-tests
- `action`: 运行模块回归、lint、build、raw UART smoke、pipe_test、cpu-tests
- `outputs`: 全部通过；raw binary 输出 `X` 并 GOOD TRAP
- `evidence`: `/tmp/npc-uartip-tests2` 23/23 PASS；lint PASS；build PASS；`/tmp/npc-uartip-pipe` PASS；cpu-tests 38/38 PASS
- `next_step`: 更新 README 和 memory

### [2026-05-22 18:55] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成
- `depends_on`: `verify`
- `inputs`: 改动清单与验证证据
- `action`: 更新 README、project-status、NPC module memory、本报告
- `outputs`: 记录完成
- `evidence`: 本目录文件
- `next_step`: 交付用户
