# OoO Pending Branch Sequencer Spec

> ⚠️ **状态(2026-07-03 RTL 重读)**:已形式化证死——`OOO_ROB_WALK_MODE=1'b1` 下三个 capture 源(direct/head0/lane1)全被 `!rob_walk_mode_i` 门死(`OooPendingDispatchArbiter.v:160-171`),`valid_o` 恒 0,pending branch 串行化全链(含 BPU pending/drained/commit 回训臂、prefetch、RecoveryGate pending 臂)随之死路;分支现走 F2 真预测 + issue 级解析 + ROB-walk;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 1. 需求

- `OooPendingBranchSequencer` 承接 `OooFrontend` 中 pending branch 单 entry
  注册状态。
- 输入只包含父模块已经仲裁好的 clear/capture 事件和 direct/head0/lane1 branch
  payload；输出 `valid/dispatched/pc/next_pc/inst/rs1/rs2/imm/cmp_op/pred_taken/
  bht_valid/bht_idx` 给 pending branch target、CompareUnit、BPU update、commit
  sequencer、fetch PC/outstanding 和 recovery helper 使用。
- 时钟域为 `clk`，复位为同步高有效；父模块可把 `rst || flush_i` 接到本模块
  `rst`，保持旧 reset/flush 全 payload 清零语义。
- 本模块不负责 branch 比较、target 计算、BPU 更新、branch-spec recovery、
  misaligned trap、backend drain、fetch redirect，也不仲裁 pending owner；这些仍归
  父模块和既有 control-flow helper。

## 2a. 协议规则

- 本模块是固定时序状态寄存器，不提供 ready/valid backpressure。
- `capture_direct_i` 表示父模块已经命中 direct branch frontend flush；本拍采样
  direct branch payload，并令 `valid_o/dispatched_o = capture_direct_valid_i`。
  这保留旧逻辑中 redirect direct branch 仍写 payload、但不建立 pending entry 的
  行为。
- `capture_head0_i` 表示 lane0 branch fast-dispatch 不可用，需要进入 precise drain
  后解析；下一拍 `valid_o=1 && dispatched_o=0`。
- `capture_lane1_i` 表示父模块已经命中 lane1 barrier 分支；本拍采样
  `capture_lane1_valid_i` 和 lane1 payload。
- `clear_dispatched_i` 只清 dispatched bit，用于 orphan stop pending 重新等待。
- `clear_i` 清 `valid/dispatched/next_pc`，不重写其余 payload，对齐旧父模块普通
  clear 只清 `pending_branch_next_pc_q` 的行为。
- `late_clear_i` 用于 CSR trap late clear，优先级高于 capture，避免同拍 stale
  pending branch 状态越过精确 trap 边界。

## 2b. 状态机

| 状态 | 条件 | 下一状态 | 输出语义 |
| --- | --- | --- | --- |
| `IDLE` | `capture_direct_i && capture_direct_valid_i` | `DISPATCHED` | valid=1, dispatched=1 |
| `IDLE` | `capture_direct_i && !capture_direct_valid_i` | `IDLE` | payload 可更新，valid=0 |
| `IDLE` | `capture_head0_i` | `HELD` | valid=1, dispatched=0 |
| `IDLE` | `capture_lane1_i && capture_lane1_valid_i` | `HELD` | valid=1, dispatched=0 |
| `IDLE` | `capture_lane1_i && !capture_lane1_valid_i` | `IDLE` | payload 可更新，valid=0 |
| `HELD/DISPATCHED` | `clear_i || late_clear_i` | `IDLE` | valid=0, dispatched=0 |
| `DISPATCHED` | `clear_dispatched_i` | `HELD` | valid=1, dispatched=0 |
| 任意 | `rst` | `IDLE` | 全 state/payload 清零 |

实现优先级：`rst > late_clear > capture_direct > capture_head0 > capture_lane1 >
clear > clear_dispatched`。capture 高于普通 clear 是为了保留旧父模块 capture block
覆盖多数 clear block 的同拍语义；late clear 单独高于 capture。

## 2c. 不变量

- I1：复位后一拍所有输出 payload 清零，`valid=0 && dispatched=0`。
- I2：direct capture 是唯一能创建 `dispatched=1` branch entry 的路径。
- I3：head0/lane1 capture 必须强制 `dispatched=0`。
- I4：任意 capture 都会覆盖 `clear_dispatched_i`，防止旧 entry dispatched 标记污染
  新 entry。
- I5：`late_clear_i` 覆盖 capture，防止 CSR trap commit 同拍 stale branch pending
  entry 穿过 privilege boundary。
- I6：普通 `clear_i` 不清 `pc/inst/rs1/rs2/imm/cmp_op/pred_taken/bht_valid/bht_idx`，
  只清 `next_pc`。

## 2d. 数据通路约束

- 数据通路只有一组 payload 寄存器：
  `pc_q/next_pc_q/inst_q/rs1_q/rs2_q/imm_q/cmp_op_q/pred_taken_q/bht_valid_q/
  bht_idx_q`。
- capture 写完整 payload；capture valid 只决定 `valid_q/dispatched_q`。
- clear mux 只驱动 `valid_q/dispatched_q/next_pc_q`，不驱动其余 payload。
- 本模块不组合依赖寄存器堆、CompareUnit、BHT、BTB 或 backend ready，避免引入
  新 ready/valid 组合环。

## 3. RTL 映射

- `OooPendingBranchSequencer.v` 的单个时序块按 2b 优先级编码。
- `OooFrontend` 继续生成 capture/clear 事件，父模块仍持有全局 pending owner、
  branch compare、BPU update、trap、redirect 和 precise recovery。
