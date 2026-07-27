# OooControlEventApplySequencer

## 1. 目的与范围

该模块是 V9O 类型化全清空事件唯一的 C0→C1 状态 owner。它把 ROB 队头稳定状态产生的
预授权记录延迟一拍，输出单拍 apply；不仲裁 fetch PC，不重新判断 CSR/trap 条件，也不读取
backend ready。

## 2. 接口

| 方向 | 信号 | 含义 |
| --- | --- | --- |
| input | `clk/rst/flush_i` | 时钟、复位、外部高优先级清空 |
| input | `request_valid_i` | C0 队头全清空预授权 |
| input | `request_reason_i[3:0]` | `TRAP` 或 `CSR_COMMIT` |
| input | `request_kill_idx_i` | 同一队头 ROB index |
| output | `apply_valid_o` | C1 单拍全清空 apply |
| output | `apply_reason_o[3:0]` | 与请求同记录 |
| output | `apply_kill_idx_o` | 与请求同记录 |

## 3. 状态与时序

状态仅为 `{valid_q,reason_q,kill_idx_q}`：

| 当前条件 | 下一状态 | 输出 |
| --- | --- | --- |
| `rst || flush_i` | valid=0 | apply=0 |
| request_valid | 锁存 reason/index，valid=1 | 输出上一拍记录 |
| 无 request | valid=0，payload 可保持 | 输出上一拍记录 |

正常使用中连续两拍 request 不可达，因为 C1 全清空会清 ROB；模块仍按一拍一记录处理，
不以“不可达”为功能依赖。

## 4. 不变量

- **CE-SEQ-I1 exact delay**：无 reset/flush 时，C1 apply 等于上一拍 C0 请求记录。
- **CE-SEQ-I2 priority**：reset/flush 压过 pending apply，不得泄露旧 reason/index。
- **CE-SEQ-I3 legal reason**：valid request/apply 仅允许 `TRAP` 或 `CSR_COMMIT`。
- **CE-SEQ-I4 no recompute**：模块只锁存/透传，不从 opcode、cause、ready 或前端状态推断字段。

## 5. 关键路径与 PPA

一组 valid、4-bit reason 与 ROB-index 寄存器；输入不读取输出 ready，无组合反馈。需以
production OOC/full-core 证据评估面积与时序，不能据位数直接宣称 PPA 中性。

## 6. 验证

focused TB 覆盖：trap、CSR commit、空闲间隔、连续请求、reset、external flush，以及
reason/index 同记录保持。集成断言覆盖 legacy shadow 等价、C0 no-new-work 与 C1 单拍 clear。

## 7. 变更记录

- 2026-07-23（V9O）：首次冻结 C0→C1 类型化 apply 状态机。
