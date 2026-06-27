# OoO Frontend Dispatch Gate

## 1. 需求

`OooFrontendDispatchGate` 负责收敛 `OooAluFetchCore` 中 dispatch 入口的纯组合 gating：

- lane1 direct JAL candidate。
- lane1 direct return candidate。
- lane1 direct branch candidate。
- lane1 barrier / unsupported 判定。
- normal dispatch fire。
- direct JAL0/JAL1、direct ret1、direct branch1 fire。

本模块只消费父模块已经计算好的 raw predicate 和 ready 信号，不解码指令、不读取 PC/ROB/CSR/RAS/FIFO，也不更新任何状态。

## 2. 协议

输入：

- `dispatch_valid_i` 表示当前 FIFO/head packet 可以进入 dispatch 组合判断。
- `dispatch0_*_i` 是 slot0 已经归类后的 dispatch predicate。
- `head1_*_raw_i` 是 slot1 原始分类 predicate。
- `head_fetch_fault1_i` 表示 slot1 fetch response fault。
- `head1_return_candidate_i` 与 `lane0_before_ret_safe_i` 已由父模块/RAS safety helper 计算。
- `dispatch*_ready_i` 与 `dispatch*_unsupported_i` 来自后端 decode/dispatch glue。

输出：

- `dispatch1_direct_jal_o`、`dispatch1_return_o`、`direct_branch1_dispatch_valid_o` 描述 lane1 可走的特殊 fast path。
- `dispatch1_barrier_o` 表示 slot1 需要形成 lane1 barrier，而不是普通双发。
- `dispatch1_control_unsupported_o` 与 `dispatch_unsupported_o` 保持旧 unsupported 边界。
- `dispatch_fire_o` 表示普通 slot0/slot1 双发。
- `dispatch1_barrier_fire_o`、`direct_jal0_fire_o`、`direct_jal1_fire_o`、`direct_ret1_fire_o`、`direct_branch1_fire_o` 是父模块后续控制使用的 action fire。

## 3. 状态机

本模块无状态、无寄存器、无 ready/valid side effect。所有输出由输入纯组合决定。

## 4. 不变量

- lane1 普通/特殊 dispatch 必须被 slot0 exit/trap/system/FP/branch/JAL/JALR 阻断。
- lane1 branch fast path 仍要求 slot1 无 fetch fault。
- lane1 barrier 必须覆盖 slot1 fetch fault、exit/system/FP/trap、不可直接处理的 branch/JALR。
- 旧 `dispatch_unsupported` 语义必须保留：它排除 slot0 branch/JALR，但不额外排除 slot0 JAL；slot0 JAL 自己由 direct JAL path 消费。
- `dispatch1_mem_unsupported_o` 当前固定为 0，表示 lane1 memory 不再作为 unsupported 边界。
- 不改变 direct branch0、pending branch/jump/mem/fp/system、commit、trap 或 redirect 时序所有权。

## 5. 数据通路

1. 计算 lane1 base：`dispatch_valid && !slot0 exit/trap/system/FP/branch/JAL/JALR`。
2. 在 lane1 base 下生成 direct JAL、return、branch candidate。
3. 在 lane1 base 下生成 barrier 与 control unsupported。
4. 普通 `dispatch_fire` 要求 lane1 base、无 barrier、无 unsupported、两个 dispatch ready。
5. direct fire 输出只做 action 组合，不修改状态。
