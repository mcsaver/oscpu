# NPC Speculative RAS Task Report

## 任务摘要

- **日期**: 2026-05-21
- **范围**: `npc/single/vsrc/BranchPredictor.v`、`npc/single/vsrc/IfStage.v`、`npc/single/testbench/tests/tb_branch_predictor.sv`
- **目标**: 在现有 BTB/BHT/RAS BPU 上加入预测期 RAS push/pop，并提供 flush checkpoint/rollback，降低 call/return 密集路径的返回地址预测滞后。

## RTL 推导摘要

### 需求

- JAL/JALR 在 IF 预测阶段即可根据 RISC-V link register hint 更新预测用 RAS。
- EX 阶段仍作为真实 control 指令解析边界，更新非投机 RAS、BTB 与 BHT。
- 预测错误、异常、mret、fence.i/cache flush、ebreak 等前端 flush 必须丢弃错误路径 RAS 修改。
- 不改变 `NpcCore` 对外端口、BTB/BHT 策略、流水线 flush/redirect 语义。

### 协议规则

- `predict_valid_i`: IF 接收一条可预测指令，允许对 `spec RAS` 做投机 push/pop。
- `update_valid_i`: EX 解析完成一条真实 control 指令，允许推进 `arch RAS` 以及 BTB/BHT。
- `rollback_i`: 前端 flush，`spec RAS` 恢复到 arch checkpoint；若与 `update_valid_i` 同拍，则恢复到应用该 resolved control update 后的 arch 状态。
- rollback 优先于同拍新预测；`IfStage` 的 `active_w` 已保证 flush 拍不再接收新 fetch response 预测。

### 状态机骨架

- BPU 无多周期事务状态机，仅维护两个栈状态：
  - `arch RAS`: 已解析到 EX 边界的非投机 RAS。
  - `spec RAS`: IF 预测使用的 RAS。
- 每拍顺序：
  1. reset 清空 BTB/RAS，BHT 初始化为弱不跳。
  2. EX update 推进 `arch RAS`、BTB、BHT。
  3. 若 rollback，`spec RAS` 恢复为 arch next。
  4. 否则若 predict valid，`spec RAS` 执行投机 push/pop。

### 不变量

- JALR 预测只读取 `spec RAS`，不会读取 `arch RAS`。
- 无 flush 的 EX update 不会再次改 `spec RAS`，避免同一 call/return 被 IF 与 EX 双重应用。
- rollback 后 `spec RAS == arch next`。
- RAS 深度保持在 `0..16`；满栈 push 沿用原策略，丢弃最老返回地址。

### 数据通路骨架

- 原 `ras_q/ras_size_q` 拆为 `ras_arch_q/ras_arch_size_q` 和 `ras_spec_q/ras_spec_size_q`。
- `predict_jalr_target_w` 使用 `ras_spec_q[ras_spec_top_idx_w]`。
- `IfStage` 将已有 `flush_i` 接入 `BranchPredictor.rollback_i`。

## 改动清单

- `BranchPredictor.v`: 新增 `rollback_i` 端口、双 RAS 状态、预测期 speculative push/pop、rollback 到 arch checkpoint。
- `IfStage.v`: 将前端 flush 连接到 BPU rollback。
- `tb_branch_predictor.sv`: 补充投机 push、投机 pop、rollback 丢弃错误路径 push、rollback 保留同拍 resolved call update 的覆盖。

## 验证证据

- `make -C npc/single lint`: PASS
- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-bpu-ras-tests run`: 21/21 PASS
- `make -C npc/single -j4`: PASS
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=if-else run NPC_RUN_ARGS='-m 0'`: PASS
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=switch run NPC_RUN_ARGS='-m 0'`: PASS
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=fact run NPC_RUN_ARGS='-m 0'`: PASS
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=recursion run NPC_RUN_ARGS='-m 0'`: PASS
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=compressed run NPC_RUN_ARGS='-m 0'`: PASS

## 剩余风险

- 当前 rollback 使用单份 arch checkpoint，适合当前顺序五级流水和 EX 解析边界；若后续做更深流水、多未决分支或乱序前端，需要升级为 per-branch checkpoint queue。
- 本轮未新增硬件性能计数器区分 RAS hit/miss 或 rollback 次数，后续做 BPU PPA/性能分析时应补。
