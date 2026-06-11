# OoO dynamic BPU direction

## 背景

- 用户问题：OoO 路径为什么没有真正的 JALR BTB / branch BPU，是否与原 BPU 冲突。
- 前置状态：上一轮已为 OoO 补上普通 JALR BTB target 预测，并把 BTB/RAS lookup 统计接到 `NpcSimTop.sv` 的层次化只读路径。
- 本轮剩余缺口：OoO 条件分支方向仍使用静态 BTFNT，host 侧 branch accuracy 也来自 commit-time 静态估算；原 `BranchPredictor` 的 gshare/local 方向预测没有进入 OoO。

## RTL 推导摘要

### 需求

- 在不改 `NpcCoreTop/OooAluFetchCore` 端口 ABI 的前提下，让 OoO 条件分支方向预测达成与原 BPU 等价的功能。
- 复用原 `BranchPredictor` 的方向预测策略：gshare BHT/GHR，local history/PHT，local strong 项覆盖 gshare。
- 预测元数据必须随 pending branch 保存，resolve/drain 时用预测时 index 训练，避免 GHR 漂移。
- 仿真统计应从 OoO 的真实 lookup/resolve 元数据上报，不再用静态 BTFNT 估算 BPU accuracy。
- out-of-scope：本轮不把顺序核 `BranchPredictor` 整体实例塞入 OoO IF 阶段；不改变已有 OoO RAS、JALR BTB、checkpoint/restore 和 fetch bridge 协议。

### 协议规则

- lookup 事件发生在 OoO 现有预测点：direct branch fire、lane0 pending branch 捕获、lane1 barrier branch 捕获。
- resolve/update 事件最多选择一个分支训练；若同拍存在 older pending branch resolve 与 younger direct branch，优先训练 pending branch，避免被可能 squash 的年轻路径污染。
- `NpcSimTop.sv` 只读层次化信号并调用 DPI，不向 RTL 反馈 ready/valid 或控制信号。
- `cpu-exec.cpp` 的 OoO commit-time 分类只统计架构控制流；branch BPU resolve 由 RTL resolve 点负责。

### 状态机

- predictor 状态：reset/flush 清 predictor 表和 pending 元数据；运行态预测表持续学习。
- pending branch 状态：捕获分支时保存 `pred_taken/bht_idx/bht_valid`；已派发 pending branch 在 backend resolve 时训练；未派发 pending branch 在 drain 后用架构比较结果训练。
- 统计状态：lookup 统计在预测点上报；resolve 统计在训练点上报；JAL/JALR/ret 仍按 commit-time 事件上报。

### 不变量

- `I1`：一个 pending branch 使用预测时保存的 BHT index 训练，不能用 resolve 时的当前 GHR 重算 index。
- `I2`：错误预测的影子取指包仍必须等真实 resolve target 匹配后才转正，不能污染 dispatch。
- `I3`：host branch BPU resolve 不双计数；commit-time 静态估算不能再进入 OoO branch accuracy。
- `I4`：仿真顶层层次化统计是只读观察，不参与硬件协议。

### 数据通路

- 新增 `branch_bht_valid_q/branch_bht_q/branch_ghr_q`。
- 新增 `branch_local_hist_q/branch_local_pht_valid_q/branch_local_pht_q`。
- 新增 pending 分支预测元数据 `pending_branch_pred_taken_q/pending_branch_bht_idx_q`。
- `branch_prefetch_branch_predict_taken_w` 从旧 `pending_branch_imm_q[31]` 改为 `pending_branch_pred_taken_q`。
- `NpcSimTop.sv` 层次化读取 `branch_bpu_lookup_*` 与 `branch_bpu_update_*`。

## 改动

- `npc/single/vsrc/ooo/OooAluFetchCore.v`
  - 增加 OoO 内部 branch direction predictor 状态表。
  - direct lane0/lane1 branch 与 pending branch 捕获时使用 gshare/local 预测。
  - resolve/drain 时训练 BHT、local PHT/history 和 GHR。
  - 暴露仿真可层次化观察的 lookup/update wires。
- `npc/single/vsrc/sim/NpcSimTop.sv`
  - OoO 宏分支新增 branch BPU lookup/resolve DPI 上报。
  - JALR BTB/RAS lookup 统计继续复用上一轮层次化路径。
- `npc/single/csrc/cpu/cpu-exec.cpp`
  - OoO commit-time branch 只调用 `npc_control_flow_event`。
  - JAL/JALR/ret 仍由 commit-time 上报 resolve 统计。

## 验证

- `make -C npc/single/testbench run TESTS=tb_ooo_alu_fetch_core`: PASS。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4`: PASS。
- `recursion`: GOOD TRAP，`cycles=5795/commits=4513`，branch accuracy `401/439`，`gshare cold=57`，JALR BTB `hit 212, miss 6`。
- CPU-test 全量：`40/40 PASS`。
  - 表：`/tmp/ooo-bpu-dynamic-full-cputests.tsv`
  - `total_cycles=64582`
  - `total_commits=78679`
  - `weighted_cpi=0.820829`
  - `highest_cpi=dummy 46/12/3.833333`
  - `lowest_cpi=crc32 8676/16305/0.532107`
  - `near_average_cpi=leap-year 1377/1692/0.813830`
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=0 -B -j4`: PASS。

## 结论

- OoO 与原 BPU 不冲突；旧问题是 OoO 实验核绕过了顺序核 `BranchPredictor` 的预测和统计数据源。
- 现在 OoO 已具备普通 JALR BTB、RAS lookup 统计，以及条件分支 gshare/local 方向预测的等价路径。
- 本轮 CPI 与上一轮 JALR BTB 后一致，说明这次主要修复预测语义和统计真实性；进一步性能收益仍需要更早的 IF 阶段预测、ROB-age selective squash 或更完整 checkpoint/rollback。
