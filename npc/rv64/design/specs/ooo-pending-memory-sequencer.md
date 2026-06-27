# OoO Pending Memory Sequencer Spec

## 1. 需求

- `OooPendingMemorySequencer` 承接 `OooAluFetchCore` 中 lane1 memory barrier 的
  pending memory 单 entry 注册状态。
- 输入只包含父模块已经仲裁好的 clear/capture/dispatch 事件和 lane1 memory
  payload；输出 `valid/dispatched/pc/inst/next_pc` 给现有 pending memory
  dispatch、commit output mux 和 fetch PC/outstanding sequencer 使用。
- 时钟域为 `clk`，复位为同步高有效；父模块可把 `rst || flush_i` 接到本模块
  `rst`，保持旧 reset/flush 全 payload 清零语义。
- 本模块不负责 LSU/MMU 请求、不产生 memory trap、不决定 PC redirect，也不仲裁
  pending owner；这些仍归父模块和已有 memory request/commit/fetch helper。

## 2a. 协议规则

- 本模块是固定时序状态寄存器，不提供 ready/valid backpressure。
- `capture_lane1_i` 表示父模块已经命中 lane1 barrier 分支；本拍采样
  `capture_valid_i` 和 payload，下一拍从输出可见。
- `dispatch_fire_i` 只将当前 entry 标记为 dispatched，不改变 payload。
- `clear_dispatched_i` 只清 dispatched bit，用于 orphan stop pending 重新等待派发。
- `clear_i` 清 `valid/dispatched/next_pc`，不重写 `pc/inst`，对齐旧父模块普通
  clear 只清 `pending_mem_next_pc_q` 的行为。
- `late_clear_i` 用于 CSR trap late clear，优先级高于 capture，避免同拍 stale
  pending memory 状态越过精确 trap 边界。

## 2b. 状态机

| 状态 | 条件 | 下一状态 | 输出语义 |
| --- | --- | --- | --- |
| `IDLE` | `capture_lane1_i && capture_valid_i` | `HELD` | valid=1, dispatched=0 |
| `IDLE` | `capture_lane1_i && !capture_valid_i` | `IDLE` | payload 可更新，valid=0 |
| `HELD` | `dispatch_fire_i` | `DISPATCHED` | valid=1, dispatched=1 |
| `HELD/DISPATCHED` | `clear_i || late_clear_i` | `IDLE` | valid=0, dispatched=0 |
| `DISPATCHED` | `clear_dispatched_i` | `HELD` | valid=1, dispatched=0 |
| 任意 | `rst` | `IDLE` | 全 state/payload 清零 |

实现优先级：`rst > late_clear > capture_lane1 > clear > dispatch_fire >
clear_dispatched`。capture 高于普通 clear 是为了保留旧父模块“capture block 在大多数
clear block 之后执行”的同拍覆盖语义；late clear 单独高于 capture。

## 2c. 不变量

- I1：复位后一拍 `valid=0 && dispatched=0 && pc/inst/next_pc=0`。
- I2：`dispatched=1` 只表示已有 pending memory entry 被送入后端；当 `valid=0`
  时 clear/capture 会把 `dispatched` 拉低。
- I3：`capture_lane1_i` 总是覆盖 `dispatch_fire_i` 和 `clear_dispatched_i`，
  防止同拍旧 entry dispatch 标记污染新 lane1 entry。
- I4：`late_clear_i` 覆盖 capture，防止 CSR trap commit 同拍 stale user memory
  pending entry 穿过 privilege boundary。
- I5：普通 `clear_i` 不清 `pc/inst`，只清 `next_pc`，避免制造与旧父模块不同的
  don't-care payload 行为。

## 2d. 数据通路约束

- 数据通路只有一组 payload 寄存器：`pc_q/inst_q/next_pc_q`。
- `capture_lane1_i` 直接写 payload；`capture_valid_i` 只决定 `valid_q`。
- clear mux 只驱动 `valid_q/dispatched_q/next_pc_q`，不驱动 `pc_q/inst_q`。
- 本模块不组合依赖 LSU/MMU 响应，也不反向影响 fetch/dispatch ready，避免引入新
  ready/valid 组合环。

## 3. RTL 映射

- `OooPendingMemorySequencer.v` 的单个时序块按 2b 优先级编码。
- `OooAluFetchCore` 继续生成 capture/clear/dispatch 事件，父模块仍持有全局
  pending owner、trap、redirect 和 memory request 仲裁。
