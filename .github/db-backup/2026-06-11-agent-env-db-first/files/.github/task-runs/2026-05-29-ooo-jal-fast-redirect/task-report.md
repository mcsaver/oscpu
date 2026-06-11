# OoO JAL 免 drain 前端重定向

## 目标

继续降低 `NPC_OOO_ALU_EXPERIMENT=1` 实验 OoO 核心在真实 AM `cpu-tests add` 上的控制流开销。上一阶段 RVC 后实验核能跑完默认 AM add，但 `cycles=3647/commits=839/CPI=4.347`；默认主线同一程序显示控制流约 35%，其中 JAL 目标在译码时已知，当前却仍走全后端 drain barrier。

## RTL 四阶段记录

### 1. 需求

- lane0/lane1 的 `JAL` 不再等待 ROB/IQ/retire 全部排空后才处理。
- `JAL` 仍作为真实 uop 进入 OoO 后端，由 ROB 按序提交并写回 link。
- 前端在 `JAL` uop dispatch fire 后立即清空 fallthrough fetch FIFO/outstanding，并从 `pc + imm_j` 重新取指。
- `JALR`、条件分支和 memory 本轮仍保持现有精确 drain barrier，不引入预测/checkpoint/rollback。
- 旧 fallthrough response 不能被误入 FIFO；若 redirect 时存在单 outstanding response，必须先丢弃该 response 再继续正常取指。

### 2. 协议/状态机/不变量

- 正常 dispatch 协议不变：后端 ready 后才能 fire；lane1 只有 lane0 fire 后才能 fire。
- lane0 JAL：
  - 只派发 lane0 JAL uop，lane1 fallthrough 被丢弃。
  - dispatch0 fire 的同拍清空 fetch FIFO，设置 `next_fetch_pc = head0_pc + head0_imm`。
- lane1 JAL：
  - lane0 普通 uop 与 lane1 JAL 可同拍双发。
  - 双发 fire 的同拍清空后续 fallthrough，设置 `next_fetch_pc = head1_pc + head1_imm`。
- stale response 丢弃：
  - redirect 同拍若 response valid，则 `fetch_rsp_ready` 消费并丢弃。
  - redirect 时若仍有 in-flight response，则进入 `discard_fetch_rsp_q`；该标志期间禁止新 request，并在消费一个 response 后清零。
- 不变量：
  - 每次 JAL redirect 只发生在对应 JAL uop 已经成功 fire 后。
  - redirect 后 FIFO 中不得保留任何 fallthrough packet。
  - 最多丢弃一个旧 response，因为实验前端只允许一个 outstanding fetch。
  - JAL link 值仍由后端 `next_pc` 写回，前端不直接写架构寄存器。

### 3. 数据通路

- 在 `OooAluFetchCore` 中拆分 `JAL` 与 `JALR`：`JAL` 走 fast redirect，`JALR` 继续 pending jump barrier。
- 新增 direct JAL redirect mux：lane0 优先，否则 lane1；target 分别来自 `head_pc_w + head0_imm_w` / `head_pc1_w + head1_imm_w`。
- `fetch_rsp_ready_o` 新增 redirect/drop 来源；`fetch_rsp_enqueue_w` 在 redirect/drop 周期屏蔽，避免 stale response 入 FIFO。
- 新增 `discard_fetch_rsp_q`，用于 redirect 后消费一条尚未返回的旧 fetch response。
- lane1 barrier 的 control 分类排除 `JAL`，使 lane1 JAL 能走正常双发路径；lane1 branch/JALR 仍为 barrier。

### 4. RTL 修改计划

- 修改 `OooAluFetchCore` 的 dispatch/control 分类、FIFO pop、fetch response enqueue/drop 和 redirect 状态更新。
- 扩展 `tb_ooo_alu_fetch_core`，新增 JAL 后存在 fallthrough packet/outstanding 时仍不会执行旧路径的覆盖。
- 跑 fetch-core、全量模块、实验 AM add、raw 4096 ALU、默认主线回归。

## 验证记录

- `tb_ooo_alu_fetch_core` 定向 PASS。
- 全量模块 testbench PASS。
- 实验 OoO AM `cpu-tests/add` GOOD TRAP：`cycles=3058`，`commits=839`，`CPI=3.645`，日志 `/tmp/ysyx-ooo-jal-fast-add.log`。
- 默认非实验路径回归保持 GOOD TRAP。

## 结果与限制

- 已保留该增量。`JAL` 不再走旧的全后端 drain barrier，而是在 dispatch fire 后立即清 fallthrough FIFO/outstanding 并重定向到目标；link 写回仍由后端 ROB/PRF/WBU 按真实 uop 提交。
- 限制：这不是完整控制流投机；`JALR`、条件分支和 memory 在该阶段仍保留各自屏障/保守路径，后续需要继续接 checkpoint/rollback 与预测状态。
