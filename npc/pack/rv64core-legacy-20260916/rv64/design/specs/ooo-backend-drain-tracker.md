# OoO Backend Drain Tracker

## 1. 需求

`OooBackendDrainTracker` 承接 `OooFrontend`(原 `OooAluFetchCore`)中 `backend_drained_q` 的单 bit 状态：

- 后端是否为空由 `control/OooPendingDrainResolveGate` 组合计算,经 glue 与父模块端口传入。
- 本模块把该事实打一拍，供 CSR/system、trap/中断注入等域 B 串行化精确边界使用
  (2026-07-03 RTL 重读:pending-mem replay 与 pending-FP 消费臂已判死/拆除,分支类不再走 drain)。
- 若本拍发生新的 dispatch fire，则下一拍不能认为后端已 drained。
- 若 precise trap/frontend global clear 发生，则强制回到 drained 状态。

本模块不读取 ROB/IQ/commit 计数，不判断 pending owner，不发起 dispatch，也不修改 trap/flush/commit 状态。

## 2. 协议

输入：

- `backend_empty_i`：上游(`control/OooPendingDrainResolveGate`,经 glue/父模块端口)已经计算好的组合事实，表示 ROB、issue queue、synthetic lane1 状态都为空，且访存退休侧静默(SQ 排空且无 drain 在飞,`mem_retire_quiet`,LSQ·SQ 切换后并入)。core retire count 不再重复参与：ROB empty 已严格蕴含本拍无 core retire，定理由 `OooAluCoreSlice` 断言守护。
- `dispatch_fire_i`：本拍有新的 dispatch0 fire，会让下一拍不能继续认为 drained。
- `force_drained_i`：trap/precise recovery 边界强制清空前端视角下的 drain tracker。

输出：

- `drained_o`：打一拍后的 drained 状态。

父模块仍负责：

- 提供 `backend_empty_i`(计算真源在 `control/OooPendingDrainResolveGate`)。
- 使用 `drained_o` 作为 CSR/system dispatch 与 pending 控制解析(drain_complete)的 gate
  (pending-mem replay/pending-FP start 消费臂已死)。
- 处理 trap、flush、commit、ROB/IQ 状态本身。

## 3. 状态机

每个时钟沿：

1. `rst`：`drained_o=1`。
2. `force_drained_i`：`drained_o=1`。
3. 普通周期：`drained_o = backend_empty_i && !dispatch_fire_i`。

`force_drained_i` 高于普通更新，匹配旧父模块中 late trap clear 覆盖默认 `backend_drained_q <= backend_drained_w && !core_dispatch0_fire_w` 的 nonblocking 赋值语义。

## 4. 不变量

- reset 后必须认为后端已 drained，允许前端从 reset PC 启动。
- 只要本拍有 dispatch fire，下一拍 `drained_o` 必须为 0，即使 `backend_empty_i` 同拍为 1。
- `force_drained_i` 同拍覆盖 dispatch fire 和 backend non-empty。
- 新模块不改变 `backend_empty_i` 的定义，不拥有 ROB/IQ/retire/synthetic commit 的判断边界。

## 5. 数据通路

1. `control/OooPendingDrainResolveGate` 汇总 `backend_empty_i`,经 glue/父模块端口送入。
2. 本模块保存 `backend_empty_i && !dispatch_fire_i`。
3. precise trap/recovery 通过 `force_drained_i` 直接写回 drained。
