# OoO Pending Jump Sequencer Spec

> ⚠️ **状态(2026-07-03 RTL 重读)**:已形式化证死——`OOO_ROB_WALK_MODE=1'b1` 下 head0/lane1 capture 均被 `!rob_walk_mode_i` 门死(`OooPendingDispatchArbiter.v:160-183`),`valid_o` 恒 0;连带 JALR-BTB 更新口(依赖 pending_jump_resolve_ready)恒 0、表恒空(`OooPredictorUpdateGate.v:17-19`);JAL/JALR 现走前端直算/RAS 投机 + issue 级解析 + ROB-walk;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 1. 需求

- `OooPendingJumpSequencer` 承接 `OooFrontend` 中 JAL/JALR pending
  jump 单 entry 注册状态。
- 输入只包含父模块已经仲裁好的 clear/capture/dispatch 事件、head0 jump
  payload、lane1 barrier payload 和 dispatch target；输出
  `valid/dispatched/jalr/pc/next_pc/inst/rs1/imm/target` 给 JALR target
  解析、BTB/RAS、pending jump dispatch、commit output mux 和 fetch
  PC/outstanding sequencer 使用。
- 时钟域为 `clk`，复位为同步高有效；父模块可把 `rst || flush_i` 接到本模块
  `rst`，保持旧 reset/flush 全 payload 清零语义。
- 本模块不负责 JAL/JALR target 计算、不读寄存器堆、不更新 RAS/BTB、不产生
  misaligned trap、不决定 PC redirect，也不仲裁 pending owner；这些仍归父模块和
  已有 control-flow helper。

## 2a. 协议规则

- 本模块是固定时序状态寄存器，不提供 ready/valid backpressure。
- `capture_head0_i` 表示父模块已经命中 lane0 JAL/JALR pending 边界；下一拍
  `valid_o=1` 且 payload 从输出可见。
- `capture_lane1_i` 表示父模块已经命中 lane1 barrier 分支；本拍采样
  `capture_lane1_valid_i` 和 lane1 payload，下一拍从输出可见。
- `dispatch_fire_i` 只将当前 entry 标记为 dispatched，并记录
  `dispatch_target_i`；不改变 PC、inst、rs1 或 imm。
- `clear_dispatched_i` 只清 dispatched bit，用于 orphan stop pending 重新等待
  派发。
- `clear_i` 清 `valid/dispatched/next_pc`，不重写 `jalr/pc/inst/rs1/imm/target`，
  对齐旧父模块普通 clear 只清 `pending_jump_next_pc_q` 的行为。
- `late_clear_i` 用于 CSR trap late clear，优先级高于 capture，避免同拍 stale
  pending jump 状态越过精确 trap 边界。

## 2b. 状态机

| 状态 | 条件 | 下一状态 | 输出语义 |
| --- | --- | --- | --- |
| `IDLE` | `capture_head0_i` | `HELD` | valid=1, dispatched=0 |
| `IDLE` | `capture_lane1_i && capture_lane1_valid_i` | `HELD` | valid=1, dispatched=0 |
| `IDLE` | `capture_lane1_i && !capture_lane1_valid_i` | `IDLE` | payload 可更新，valid=0 |
| `HELD` | `dispatch_fire_i` | `DISPATCHED` | valid=1, dispatched=1, target 更新 |
| `HELD/DISPATCHED` | `clear_i || late_clear_i` | `IDLE` | valid=0, dispatched=0 |
| `DISPATCHED` | `clear_dispatched_i` | `HELD` | valid=1, dispatched=0 |
| 任意 | `rst` | `IDLE` | 全 state/payload 清零 |

实现优先级：`rst > late_clear > capture_head0 > capture_lane1 > clear >
dispatch_fire > clear_dispatched`。capture 高于普通 clear 是为了保留旧父模块
“capture block 在大多数 clear block 之后执行”的同拍覆盖语义；late clear 单独高于
capture。

## 2c. 不变量

- I1：复位后一拍所有输出 payload 清零，`valid=0 && dispatched=0 && jalr=0`。
- I2：`dispatched=1` 只表示已有 pending jump entry 被送入后端；当 `valid=0`
  时 clear/capture 会把 `dispatched` 拉低。
- I3：任意 capture 都会覆盖 `dispatch_fire_i` 和 `clear_dispatched_i`，防止同拍旧
  entry dispatch 标记污染新 entry。
- I4：`late_clear_i` 覆盖 capture，防止 CSR trap commit 同拍 stale user jump
  pending entry 穿过 privilege boundary。
- I5：普通 `clear_i` 不清 `jalr/pc/inst/rs1/imm/target`，只清 `next_pc`，避免制造
  与旧父模块不同的 don't-care payload 行为。
- I6：`dispatch_fire_i` 不得改变 `valid/jalr/pc/next_pc/inst/rs1/imm`，只更新
  `dispatched/target`。

## 2d. 数据通路约束

- 数据通路只有一组 payload 寄存器：
  `jalr_q/pc_q/next_pc_q/inst_q/rs1_q/imm_q/target_q`。
- `capture_head0_i` 写完整 head0 payload 并强制 `valid_q=1`。
- `capture_lane1_i` 写完整 lane1 payload；`capture_lane1_valid_i` 只决定
  `valid_q`。
- clear mux 只驱动 `valid_q/dispatched_q/next_pc_q`，不驱动
  `jalr_q/pc_q/inst_q/rs1_q/imm_q/target_q`。
- 本模块不组合依赖寄存器堆、BTB、RAS 或 backend ready，避免引入新 ready/valid
  组合环。

## 3. RTL 映射

- `OooPendingJumpSequencer.v` 的单个时序块按 2b 优先级编码。
- `OooFrontend` 继续生成 capture/clear/dispatch 事件，父模块仍持有全局
  pending owner、trap、redirect、RAS/BTB 和 JALR target 仲裁。
