# OoO Direct Branch Wait Buffer

> ⚠️ **状态(2026-07-03 RTL 重读)**:mode=1(`OOO_ROB_WALK_MODE=1'b1`)下本模块唯一有意义的消费臂 `direct_branch_wait_untracked` 在 `OooBranchResolveRecoveryGate.v:59-66` 的 mode=1 分支被丢弃(untracked 判据收紧为"仅后端显式 mispredict"),模块只剩置位/自清空转,等效死逻辑;拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 1. 需求

`OooDirectBranchWaitBuffer` 承接 `OooFrontend`(原 `OooAluFetchCore`)中 direct branch 等待后端 resolve 的单 entry 状态：

- 当 direct branch fire 但当拍没有匹配的 resolve 时，保存该 branch PC。
- 当后续后端 resolve PC 命中时，清除等待状态。
- 当 precise trap/frontend global clear 发生时，丢弃等待状态。

本模块只持有 `pending/pc`，不判断 branch 方向、不选择 redirect PC、不更新 BPU/RAS/FIFO/ROB/CSR，也不修改 stop-pending 或 trap/commit 状态。

## 2. 协议

输入：

- `clear_i`：父模块给出的高优先级清理动作。
- `resolve_match_i`：父模块已判断当前后端 resolve 命中等待 PC。
- `branch_fire_i`：当前 direct branch action fire。
- `branch_resolve_valid_i`：当前 direct branch fire 同拍是否已有 resolve。
- `branch_pc_i`：当前 direct branch PC。

输出：

- `pending_o`：存在未被后端 resolve 匹配的 direct branch。
- `pc_o`：等待 resolve 的 branch PC。

父模块仍负责：

- 计算 direct branch fire 和 direct branch PC。
- 将 `pending_o/pc_o` 与后端 resolve PC 比较。
- 处理 untracked resolve、redirect、trap、BPU update 和 frontend flush。

## 3. 状态机

每个时钟沿：

1. `rst`：清 pending 和 PC。
2. `clear_i`：清 pending 和 PC。
3. 普通周期：
   - 若 `resolve_match_i`，清 pending 和 PC。
   - 若 `branch_fire_i`，则 `pending = !branch_resolve_valid_i`；若当拍已 resolve，PC 清零，否则保存 `branch_pc_i`。

`resolve_match_i` 与 `branch_fire_i` 同拍时，新的 branch fire 覆盖旧 match clear，匹配旧父模块两个顺序 `if` 的 nonblocking 赋值语义。

## 4. 不变量

- `pending_o == 0` 时 `pc_o` 必须为 0。
- `pending_o == 1` 时 `pc_o` 是最近一次未同拍 resolve 的 direct branch PC。
- `clear_i` 高于 resolve match 和 branch fire，避免 trap/recovery 后保留用户态旧等待项。
- 新模块不观察后端 resolve payload，不决定 resolve 是否 valid；这些仍由父模块负责。

## 5. 数据通路

1. arm path：`branch_fire_i && !branch_resolve_valid_i -> pending_o/pc_o`。
2. same-cycle resolved path：`branch_fire_i && branch_resolve_valid_i -> pending_o=0, pc_o=0`。
3. match path：`resolve_match_i -> pending_o=0, pc_o=0`。
4. clear path：`clear_i -> pending_o=0, pc_o=0`。
