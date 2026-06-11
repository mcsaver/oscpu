# OoO RAS return fast path

## 背景

JAL 快速重定向与 lane0 memory 免预 drain 后，实验 OoO 路径运行默认 AM `cpu-tests add` 为 `cycles=2886/commits=839/CPI=3.440`。反汇编显示该程序大量调用 `check`，调用点为 `c.jal`，返回点主要为 `c.jr x1`（内部解压成 `jalr x0, 0(x1)`）。当前一般 JALR 仍会等待 ROB/IQ/retire 全部 drain 后才派发并重定向，是剩余主要瓶颈之一。

## 四阶段记录

### 1. 需求

- 增加受限 return-address stack（RAS）fast path，只覆盖 `jalr x0, 0(x1/x5)` 且 RAS 非空的返回。
- 普通 JALR、RAS 空、非 link-register 返回保持原精确 drain 路径。
- JAL/JALR 仍真实进入后端/ROB；fast return 只改变前端 redirect 时机。

### 2. 协议 / 状态机 / 不变量

- 已知目标 JAL fire 时，若 rd 为 `x1/x5`，把该 JAL 的真实 `next_pc` 压入 RAS。
- fast return fire 时，从 RAS 栈顶取预测目标、弹栈、清空 fallthrough FIFO/outstanding，并立即 redirect 到预测目标；返回 uop 同拍进入后端。
- 若返回不匹配受限形态或 RAS 空，则完全回落到既有 pending jump drain，不改变 correctness envelope。
- 该增量暂不做 mispredict recovery；这是实验核面向当前 AM add 的受限优化，后续完整 OoO 需要 checkpoint/rollback 后才能推广到一般 JALR/BTB/RAS 预测。

### 3. 数据通路

- 在 `OooAluFetchCore` 增加小型 8-entry RAS：`ras_stack_q` 与 `ras_count_q`。
- JAL direct path 提供 call push 信息：选择 lane0/lane1 的 rd 与 `head_next_pc*`。
- lane0 return fast path 增加 `direct_ret0_dispatch_valid_w/direct_ret0_fire_w/direct_ret_target_w`，纳入 `core_dispatch0_valid_w` 与 frontend flush/drop。

### 4. RTL 实施计划

- 修改 `npc/single/vsrc/ooo/OooAluFetchCore.v` 的 RAS 状态、dispatch 分类、direct flush target mux 和 always 更新。
- 扩展 `tb_ooo_alu_fetch_core`，覆盖 `JAL -> return` fast path 与 RAS 命中重定向。
- 回归 fetch-core、全量模块 testbench、实验构建与 AM add。

