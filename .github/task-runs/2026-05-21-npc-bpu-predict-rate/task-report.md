# NPC BPU 预测率优化与统计

## 任务概览

- 日期：2026-05-21
- 范围：`npc/single` BPU RTL、前端/流水元数据、仿真 DPI 事件、host 统计报告、相关 testbench
- 目标：落盘 BPU 统计、BHT valid+BTFNT、gshare 降 alias、BTB 扩容、RAS 细分统计；RAS 深度本轮不扩大

## RTL 推导摘要

### 需求

- IF 预测阶段仍输出 `predict_next_pc`，EX 解析阶段仍以 `id_ex_pred_pc != ex_control_next_pc` 判定误预测。
- BHT 冷启动不再固定弱不跳转，未训练表项用 BTFNT：后向分支预测 taken，前向分支预测 not taken。
- BHT 降低 PC 低位直接索引 alias：改为 10-bit GHR 的 1024-entry gshare。
- 统计需要覆盖 branch/JAL/JALR/ret next-PC 正确率、BTB hit/miss、BHT correct/miss/cold、RAS hit/underflow/overflow。
- `NpcCore` 端口 ABI 不新增仿真统计端口，统计继续由 `NpcSimTop` 层次化观察并通过 DPI 传给 host。

### 协议规则

- IF 阶段 `predict_valid` 发生时，`BranchPredictor` 组合给出 next PC 与预测元数据。
- BHT update 发生在 EX `bpu_update_valid` 同拍，必须使用该指令在 IF 预测时生成的 gshare index，而不是 EX 当前 GHR 重新计算。
- GHR 只在已解析且非异常的条件分支上更新，不做预测期投机更新，因此不需要 flush rollback。
- lookup 统计按 IF 预测点计数，用于观察表项命中；resolve 统计按 EX 解析点计数，用于最终正确率。

### 状态机

- BHT/GHR 无额外多拍状态机：reset 清 valid/GHR；predict 组合查表；update 在时钟沿写 valid/counter/GHR。
- RAS 保持既有 `arch RAS + spec RAS` 模型：predict 投机 push/pop；flush rollback 到 arch checkpoint；update 推进 arch。
- BTB 保持直接映射单拍查表/单拍更新，本轮只从 128 项扩到 256 项。

### 不变量

- `id_ex_bht_idx_q` 必须来自同一条指令的 IF 预测上下文；EX 不重新计算 gshare index。
- GHR 仅由 resolved branch 修改；flush 不改变 GHR。
- RAS overflow 只在投机 push 且 spec 栈已满时计数；ret underflow 以 RAS lookup miss 表达。
- DPI 统计事件不得反向影响 RTL 控制、流水推进或架构状态。

### 数据通路约束

- `predict_bht_idx` 从 `BranchPredictor -> IfStage -> IfIdPipeReg -> IdExPipeReg -> BranchPredictor update` 闭环传递。
- `NpcSimTop` 通过 `u_core.u_if_stage.*` 观察 lookup，通过 `u_core.id_ex_* / ex_control_*` 观察 resolve。
- host 侧 `BpuStats` 独立于原 branch/jump 动态次数统计，报告时合并展示。

## 改动清单

- `BranchPredictor.v`：BTB 扩到 256；BHT 扩到 1024-entry gshare；新增 BHT valid+BTFNT；新增预测元数据输出。
- `IfStage.v`、`IfIdPipeReg.v`、`IdExPipeReg.v`、`NpcCore.v`：携带并回传 `predict_bht_idx`。
- `NpcSimTop.sv`、`cpu-exec.cpp`：新增 BPU lookup/resolve DPI 事件和统计打印。
- `tb_branch_predictor.sv`、`tb_if_stage.sv`、`tb_pipe_regs.sv`、`stage_pipe_test.sv`：补齐新增端口与 BTFNT/gshare 覆盖。

## 验证证据

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-bpu-stats-tests run`：21/21 PASS。
- `make -C npc/single lint`：PASS。
- `make -C npc/single -j4`：PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=if-else run NPC_RUN_ARGS='-m 0 --no-progress'`：PASS，输出 BPU 统计，如 branch accuracy `61/73`、return accuracy `16/16`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL='switch recursion compressed' run NPC_RUN_ARGS='-m 0 --no-progress'`：3/3 PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0 --no-progress'`：38/38 PASS。

## 后续建议

- 用 CoreMark/MicroBench 长样本比较 gshare 与旧 256-entry direct BHT 的 mispredict 分布。
- 若 JALR accuracy 低于 return accuracy，优先继续看非 ret 间接跳转 BTB hit/miss，而不是扩大 RAS。
- 若 BHT cold 长期偏高，可评估更短 GHR、局部历史或 bimodal+gshare hybrid。
