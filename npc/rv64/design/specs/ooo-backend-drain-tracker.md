# OoO Backend Drain Tracker

## 1. 需求

`OooBackendDrainTracker` 承接 `OooAluFetchCore` 中 `backend_drained_q` 的单 bit 状态：

- 父模块组合计算当前后端是否为空。
- 本模块把该事实打一拍，供 CSR/system、memory replay、FP pending 等精确边界使用。
- 若本拍发生新的 dispatch fire，则下一拍不能认为后端已 drained。
- 若 precise trap/frontend global clear 发生，则强制回到 drained 状态。

本模块不读取 ROB/IQ/commit 计数，不判断 pending owner，不发起 dispatch，也不修改 trap/flush/commit 状态。

## 2. 协议

输入：

- `backend_empty_i`：父模块已经计算好的组合事实，表示 ROB、issue queue、retire 和 synthetic lane1 状态都为空。
- `dispatch_fire_i`：本拍有新的 dispatch0 fire，会让下一拍不能继续认为 drained。
- `force_drained_i`：trap/precise recovery 边界强制清空前端视角下的 drain tracker。

输出：

- `drained_o`：打一拍后的 drained 状态。

父模块仍负责：

- 计算 `backend_empty_i`。
- 使用 `drained_o` 作为 pending replay、CSR dispatch、FP pending start 的 gate。
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

1. 父模块汇总 `backend_empty_i`。
2. 本模块保存 `backend_empty_i && !dispatch_fire_i`。
3. precise trap/recovery 通过 `force_drained_i` 直接写回 drained。
