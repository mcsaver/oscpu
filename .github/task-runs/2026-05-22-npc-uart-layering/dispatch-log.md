# Dispatch Log

## 基本信息

- `task_id`: `2026-05-22-npc-uart-layering`
- `task_slug`: `npc-uart-layering`
- `graph_template`: `am-device-loop`
- `log_policy`: `append-only`

---

### [2026-05-22 18:58] `recall` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户指出 UART 应为单独模块，再接入 AXI，而不是 AXI/UART 合体模块
- `depends_on`: 无
- `inputs`: 已读项目规则、NPC memory、现有 UART 初版实现
- `action`: 明确需要保留 crossbar AXI slave 边界，但拆出独立 native UART core
- `outputs`: RTL 四段推导
- `evidence`: 对话内推导摘要
- `next_step`: 拆分 RTL 与 testbench

### [2026-05-22 19:05] `implement` - `completed`

- `owner_agent`: Codex
- `trigger`: 分层设计完成
- `depends_on`: `recall`
- `inputs`: 初版 `AxiUartLite` AXI-Lite 握手逻辑和 UART 寄存器语义
- `action`: 新增 `Uart` native 设备核心和 `AxiLiteToUart` 适配层，更新 filelist、`NpcSimTop` 实例名和模块 testbench
- `outputs`: 代码落盘
- `evidence`: `tb_uart` 与 `tb_axi_lite_to_uart` 后续验证通过
- `next_step`: 运行验证

### [2026-05-22 19:20] `verify` - `completed`

- `owner_agent`: Codex
- `trigger`: 实现完成
- `depends_on`: `implement`
- `inputs`: testbench、Verilator、临时 raw binary、AM cpu-tests
- `action`: 运行模块回归、lint、build、raw UART smoke、pipe_test、cpu-tests
- `outputs`: 全部通过；raw binary 输出 `X` 并 GOOD TRAP
- `evidence`: `/tmp/npc-uart-layer-tests` 24/24 PASS；lint PASS；build PASS；`/tmp/npc-uart-layer-pipe` PASS；cpu-tests 38/38 PASS
- `next_step`: 更新 README 和 memory

### [2026-05-22 19:35] `record` - `completed`

- `owner_agent`: Codex
- `trigger`: 验证完成
- `depends_on`: `verify`
- `inputs`: 改动清单与验证证据
- `action`: 更新 README、project-status、NPC module memory、本报告
- `outputs`: 记录完成
- `evidence`: 本目录文件
- `next_step`: 交付用户
