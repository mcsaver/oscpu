# OoO Frontend Dispatch Gate

> **状态（2026-07-11）**：模块仍在活跃主路径；本文同时记录 CURRENT 行为与
> `FDG-G1` 开放合同，不把已分类为 trap 误写成已经阻止 backend dispatch。

## 1. 需求

`OooFrontendDispatchGate` 负责收敛 `OooAluFetchCore`（现已重构为 `OooFrontend`
wrapper）中 dispatch 入口的纯组合 gating：

- lane1 direct JAL candidate。
- lane1 direct return candidate。
- lane1 direct branch candidate。
- lane1 barrier / unsupported 判定。
- normal dispatch fire。
- direct JAL0/JAL1、direct ret1 fire。`direct_branch1_fire_o` 是兼容输出，当前固定为 0；
  taken 预测已经前移到 fetch-response，dispatch 拍不再执行 branch1 fast fire。
- 【F2】head0 分支双发资格 `dbranch_dual_go`（预测 not-taken 且 head1 平凡 →
  不 fire 不 flush，原子双发）与 domain-A 分支普通 dispatch fire
  `dbranch_dispatch_fire`（FIFO pop 源）。

本模块只消费父模块已经计算好的 raw predicate 和 ready 信号，不解码指令、不读取 PC/ROB/CSR/RAS/FIFO，也不更新任何状态。

## 2. 协议

输入：

- `dispatch_valid_i` 表示当前 FIFO/head packet 可以进入 dispatch 组合判断。
- `dispatch0_*_i` 是 slot0 已经归类后的 dispatch predicate。
- `head1_*_raw_i` 是 slot1 原始分类 predicate。
- `head_fetch_fault1_i` 表示 slot1 fetch response fault。
- `head1_return_candidate_i` 与 `lane0_before_ret_safe_i` 已由父模块/RAS safety helper 计算。
- `dispatch*_ready_i` 与 `dispatch*_unsupported_i` 来自后端 decode/dispatch glue。
- 【F2】`head0/head1_branch_pred_taken_i` 是纯 BHT 寄存输出（不含 ready，防组合环）；
  `dispatch*_unsupported_raw_i` 是裸支持性（纯 inst 组合，dual_go 谓词专用）；
  `dispatch0_return_i` 用于区分返回/非返回 JALR（B2 de-pend）。

输出：

- `dispatch1_direct_jal_o`、`dispatch1_return_o`、`direct_branch1_dispatch_valid_o` 描述 lane1 可走的特殊 fast path。
- `dispatch1_barrier_o` 表示 slot1 需要形成 lane1 barrier，而不是普通双发。
- `dispatch1_control_unsupported_o` 与 `dispatch_unsupported_o` 保持旧 unsupported 边界。
- `dispatch_fire_o` 表示普通 slot0/slot1 双发。
- `dispatch1_barrier_fire_o`、`direct_jal0_fire_o`、`direct_jal1_fire_o`、
  `direct_ret1_fire_o` 是父模块后续控制使用的 action fire；
  `direct_branch1_fire_o` 当前固定为 0。
- `dbranch_dual_go_o`、`dbranch_dispatch_fire_o`、`frontend_dispatch_to_backend_valid_o`、`lane1_barrier_dispatch0_valid_o` 供 dispatch mux 与 FIFO pop 消费。

## 3. 状态机

本模块无状态、无寄存器、无 ready/valid side effect。所有输出由输入纯组合决定。

## 4. 不变量

- lane1 普通/特殊 dispatch 必须被 slot0 exit/trap/system/JAL/JALR 阻断；slot0
  分支仅在非 `dbranch_dual_go` 时阻断（F2），slot0 FP 已迁域 A、不再阻断 lane1。
- lane1 branch fast path 仍要求 slot1 无 fetch fault。
- lane1 barrier 必须覆盖 slot1 fetch fault、exit/system/trap、不可直接处理的
  branch/JALR；slot1 FP 已迁域 A 走普通双发，非返回 JALR 在
  `OOO_ROB_WALK_MODE=1` 下走 de-pend 双发（`dispatch1_depend_jump`）而非 barrier。
- 旧 `dispatch_unsupported` 语义必须保留：它排除 slot0 branch/JALR，但不额外排除 slot0 JAL；slot0 JAL 自己由 direct JAL path 消费。
- `dispatch1_mem_unsupported_o` 当前固定为 0，表示 lane1 memory 不再作为 unsupported 边界。
- 不改变 direct branch0、仍活的 pending system/trap、commit 或 redirect 时序所有权；
  已删除的 pending branch/jump/mem/fp 四类不再属于本模块职责。
- **CURRENT**：head1 `arch_trap` 形成 barrier，只允许更老的 slot0 走
  `lane1_barrier_dispatch0_valid_o`；trap 槽本身不作为普通 lane1 backend dispatch。
- **KNOWN GAP FDG-G1**：head0 的承重合同应为
  `dispatch0_arch_trap_i -> !frontend_dispatch_to_backend_valid_o`。当前 RTL 的主
  backend valid 方程没有该门控，trap-classified head0 仍可呈现给 backend。四类 FP
  代表编码已动态覆盖到本 gate；最终 ROB 停顿或执行后果仍属整链静态判断。

## 5. 数据通路

1. 计算 lane1 base：`dispatch_valid && !slot0 exit/trap/system/JAL/JALR &&
   (!slot0 branch || dbranch_dual_go)`（slot0 FP 不参与阻断）。
2. 在 lane1 base 下生成 direct JAL、return、branch candidate。
3. 在 lane1 base 下生成 barrier 与 control unsupported。
4. 普通 `dispatch_fire` 要求 lane1 base、无 barrier、无 unsupported、两个 dispatch ready。
5. direct JAL/return fire 只做 action 组合，不修改状态；branch1 fire 固定为 0。

## 6. 验证补充（2026-07-11）

- 必须保留合法 FADD.S 的正对照。
- 必须覆盖 unknown OP-FP funct7、reserved FMA fmt、reserved static rm、
  DYN+reserved frm，并检查 `arch_trap && frontend_dispatch_to_backend_valid`。
- 当前上述反例是 **KNOWN GAP**，不得把测试目标写成已满足的不变量。
