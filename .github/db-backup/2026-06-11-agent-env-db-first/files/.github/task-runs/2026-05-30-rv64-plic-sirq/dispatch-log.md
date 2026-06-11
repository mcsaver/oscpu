# Dispatch Log

## 基本信息

- `task_id`: `2026-05-30-rv64-plic-sirq`
- `task_slug`: `rv64-plic-sirq`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-30 20:40] `rtl-derive-plic` - `completed`

- `owner_agent`: Codex
- `trigger`: 继续推进 RV64 Linux boot 前置平台设备能力。
- `depends_on`: S-mode external interrupt focused path 已由 `tb_ooo_priv_system` 验证，但缺真实 PLIC-like MMIO 设备。
- `inputs`: 当前 AXI-Lite slave 结构、RV64 LSU 8-byte aligned lane 访问规则、Linux PLIC priority/pending/enable/threshold/claim 基本模型。
- `action`: 推导并实现单 source M/S context PLIC-like 设备：source pending、priority、enable、threshold、claim clear、completion write no-op、external IRQ 输出。
- `outputs`: `npc/rv64/vsrc/bus/AxiLitePlic.v`
- `evidence`: 后续 `tb_axi_lite_plic` 与 `plic-sirq` 均 PASS。
- `handoff_to`: `wire-platform`
- `next_step`: 接入 `NpcSimTop` 地址图和 core external IRQ。
- `notes`: 当前 `source_irq_i` 先绑 `0`，测试通过 MMIO pending 注入。

### [2026-05-30 20:55] `wire-platform` - `completed`

- `owner_agent`: Codex
- `trigger`: PLIC RTL 需要进入真实 `NpcSimTop`，不能只停在孤立单测。
- `depends_on`: `rtl-derive-plic`
- `inputs`: `define.v`, `filelist.mk`, `NpcSimTop.sv`
- `action`: 新增 `NPC_AXI_PLIC_BASE/MASK`，把 PLIC 加入 RV64 filelist 和 AXI slave 表，扩展 `AXI_S_COUNT`，将 `plic_external_irq_w` 接到 `NpcCoreTop.irq_external_i`。
- `outputs`: PLIC 可由真实 CPU 通过 `0x0c00_0000` 访问。
- `evidence`: `make -C npc/sim BACKEND=rv64 lint` PASS。
- `handoff_to`: `unit-test-plic`
- `next_step`: 写 PLIC focused testbench。
- `notes`: PLIC 不加入 default stub mask。

### [2026-05-30 21:10] `unit-test-plic` - `completed`

- `owner_agent`: Codex
- `trigger`: 先用模块级 AXI-Lite testbench 收口寄存器 side effect。
- `depends_on`: `rtl-derive-plic`
- `inputs`: `AxiLitePlic.v`
- `action`: 新增 `tb_axi_lite_plic`，覆盖 reset、priority、S enable、threshold、source irq pending、claim clear、software pending、split AW/W、aligned lane priority access。
- `outputs`: `npc/rv64/testbench/tests/tb_axi_lite_plic.sv`
- `evidence`: focused `tb_axi_lite_plic tb_axi_lite_clint tb_ooo_priv_system tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_int_backend` 6/6 PASS。
- `handoff_to`: `mini-boot-plic-sirq`
- `next_step`: 用真实 cpu-test 走 S-mode 外部中断路径。
- `notes`: focused 回归包含此前 privilege/Sv39/mem bridge 关键路径。

### [2026-05-30 21:25] `mini-boot-plic-sirq` - `completed`

- `owner_agent`: Codex
- `trigger`: PLIC 需要端到端证明能驱动 core external IRQ 和 S-mode trap。
- `depends_on`: `wire-platform`, `unit-test-plic`
- `inputs`: `am-kernels/tests/cpu-tests`
- `action`: 新增 `plic-sirq.c`：M-mode handoff 到 S-mode，S-mode 配 PLIC/SIE/SSTATUS，通过 pending bit1 注入 source 1，`wfi` 后进 S handler，读取 claim=1、complete、`sret`。
- `outputs`: `am-kernels/tests/cpu-tests/tests/plic-sirq.c`
- `evidence`: `plic-sirq` PASS，`HIT GOOD TRAP`，`cycles=399/commits=98/CPI=4.071`。
- `handoff_to`: `regression-smoke`
- `next_step`: 复跑 lint/build 和基础 `add` smoke。
- `notes`: `plic-sirq` 是控制流/设备 smoke，不作为 CPI 基准。

### [2026-05-30 21:36] `regression-smoke` - `completed`

- `owner_agent`: Codex
- `trigger`: 确认新增 AXI slave 和 IRQ 接线没有破坏普通路径。
- `depends_on`: `mini-boot-plic-sirq`
- `inputs`: rv64 lint/build、`add` cpu-test
- `action`: 串行运行 focused testbench、rv64 lint、rv64 build、`plic-sirq`、`add`，避免当前 WSL/vsock 不稳定被并发放大。
- `outputs`: 验证证据闭环。
- `evidence`: focused 6/6 PASS；`make -C npc/sim BACKEND=rv64 lint` PASS；`make -C npc/sim BACKEND=rv64 -j4` PASS；`plic-sirq` PASS；`add` PASS，`cycles=755/commits=839/CPI=0.900`。
- `handoff_to`: `memory-record`
- `next_step`: 更新 `.github/memory/*` 与 task-run。
- `notes`: 真实 Linux boot 仍未完成。

### [2026-05-30 21:41] `memory-record` - `completed`

- `owner_agent`: Codex
- `trigger`: 仓库规则要求完成后同步 project/module/task-run 记忆。
- `depends_on`: `regression-smoke`
- `inputs`: 修改清单、验证命令、已知限制。
- `action`: 更新 project status、NPC/AM 模块笔记、known issue，并创建本目录 task report/dispatch log。
- `outputs`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/modules/am-kernels.md`, `.github/memory/known-issues.md`, `.github/task-runs/2026-05-30-rv64-plic-sirq/*`
- `evidence`: 本文件与 task report。
- `handoff_to`: none
- `next_step`: 多源 PLIC/virtio/DTB/SBI/真实 kernel 镜像加载。
- `notes`: 不把 mini boot interrupt smoke 误报为完整 Linux boot。
