# Task Report

## 基本信息

- `task_id`: `2026-05-21-npc-bpu-local-history`
- `task_slug`: `npc-bpu-local-history`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-21`
- `updated_at`: `2026-05-21`

## 任务目标

- `source_request`: 用户给出 CoreMark/NPC 复跑统计，要求继续优化核心。
- `goal`: 基于真实统计定位下一轮有效优化点，并完成可验证的 RTL 微结构改动；按用户后续要求将 BPU 方向表开局偏置改为弱跳转。
- `scope`: `BranchPredictor.v`、`NpcCore.v`、`tb_branch_predictor.sv`、`cpu-exec.cpp` 与项目记忆。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 这是 benchmark-driven 的 BPU 微结构调参，不属于固定 bring-up 或设备回归模板。
- `dynamic_nodes_added`: `map-hot-pc`, `rtl-derive`, `implement-local-history`, `verify-benchmark`, `record`
- `why_dynamic_nodes_were_needed`: 用户提供的 top miss PC 改变了优化方向，需要先把 PC 映射到 CoreMark 热点再决定结构。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | `.github/AGENTS.md`、memory、NPC study README | 任务约束与当前 NPC 状态 | 已读取必读链 |
| map-hot-pc | codex | completed | 用户 top branch miss PCs、CoreMark 反汇编 | miss 集中在字符状态机和链表遍历 | `0x80000c56/0x80000b8e/...` 映射到 `core_state_transition` 等 |
| rtl-derive | codex | completed | BPU 当前 gshare/RAS/BTB 接口 | local-history 方向预测方案 | 本文件“RTL 推导摘要” |
| implement-local-history | codex | completed | `BranchPredictor.v` 与单测 | 256-entry local history + 1024-entry local PHT | 文件修改 |
| verify | codex | completed | 改动后的 RTL/C++ | testbench/lint/build/CoreMark/cpu-tests 通过 | 见“验证证据” |
| weak-taken-init | codex | completed | 用户复跑结果和“bpu 开局改成弱跳转”要求 | gshare BHT/local PHT reset counter 改为 `2'd2`，单测补 reset 检查 | CoreMark/cpu-tests 复验 |
| record | codex | completed | 本轮结果 | memory 与 task-runs 更新 | `.github/memory/project-status.md`、`.github/memory/modules/npc.md` |

## RTL 推导摘要

### 阶段 1 - 需求

- 功能目标：降低 CoreMark 条件分支方向误预测，尤其是同一 PC 上呈现局部输入模式的分支。
- 端口边界：不改变 `BranchPredictor` 对外端口，不改 `IfStage/IfId/IdEx` 的 BHT index 携带链；继续保持 gshare index 精确更新。
- 性能约束：预测仍为 IF response 同周期组合 lookup；训练仍在 EX resolve 的 `update_valid_i` 周期完成。
- out-of-scope：本轮不做 tournament chooser 额外 pipe payload、不做 BTB/JALR/RAS 调整、不改 cache。

### 阶段 2a - 协议规则

- `predict_valid_i` 有效时组合读取 BTB/gshare/local/RAS，输出 `predict_next_pc_o`。
- `update_valid_i && update_is_branch` 时训练 gshare 与 local；local history 使用更新前的 per-PC history 形成 PHT index，再在同一拍移入实际方向。
- local predictor 只在 PHT valid 且 counter 为 `00/11` 强置信时覆盖 gshare；冷启动与弱置信回退到原 gshare/BTFNT。
- `rollback_i` 仍只负责 spec RAS rollback，local history 为非投机 resolve 更新，不参与 rollback。

### 阶段 2b - 状态机

- 本轮没有新增多拍 FSM。
- reset：清空 local history、local PHT valid，gshare BHT 与 local PHT counter 均初始化为 weak taken；valid 仍清 0，所以 cold branch 第一轮继续由 BTFNT 决定。
- predict：组合计算 gshare 方向、local 方向、local 强置信 mux，随后用于 branch target/seq pc 选择。
- update：条件分支 resolve 时饱和更新 gshare 与 local PHT，最后移入 local history 和 GHR。

### 阶段 2c - 不变量

- local history index 范围固定为 256 entry，PHT index 固定为 `{pc[2:1], local_history[7:0]}`，不会越界。
- local/gshare 2-bit counter 只做饱和加减，值域保持 `0..3`。
- local cold/weak 时不得覆盖 gshare，避免新表刚启动时降低已有预测率。
- gshare 仍使用 IF 阶段携带到 EX 的 `update_bht_idx_i` 更新，保留上一轮“预测上下文 index”不变量。

### 阶段 2d - 数据通路约束

- 新增数据通路：`pc[8:1] -> local_hist_q`，`{pc[2:1], local_hist}` -> local PHT counter/valid。
- branch 方向 mux：`local_strong ? local_taken : gshare_taken`。
- update 数据通路：`update_pc[8:1]` 取旧 local history，训练对应 PHT 后把 `update_taken_i` shift-in。
- 关键路径预算：新增 local lookup 是 256-entry history + 1024-entry 2-bit PHT 的组合读，与现有 gshare 并行，最终只增加一个小 mux。

## 关键产物

- `artifacts`: local-history BPU 方向预测、BPU 单测交替模式覆盖、统计文案从纯 BHT 调整为 direction predictor。
- `logs_or_traces`: CoreMark 长测输出、module testbench summary、cpu-tests 38/38 PASS 输出。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 验证证据

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-bpu-local-tests run`: 21/21 PASS。
- `make -C npc/single lint`: PASS。
- `make -C npc/single -j14`: PASS。
- `./npc/single/build/NpcSimTop am-kernels/benchmarks/coremark/build/coremark-riscv32-npc.bin -m 0 --no-progress`: GOOD TRAP，`cycles=390478755`、`CPI=1.285`、branch miss `2457500`、branch accuracy `95.8%`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS。
- `git diff --check -- npc/single/vsrc/BranchPredictor.v npc/single/testbench/tests/tb_branch_predictor.sv npc/single/vsrc/NpcCore.v npc/single/csrc/cpu/cpu-exec.cpp`: PASS。

### 弱跳转初值补充验证

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-bpu-weak-taken-tests run`: 21/21 PASS。
- `make -C npc/single lint`: PASS。
- `make -C npc/single -j14`: PASS。
- `./npc/single/build/NpcSimTop am-kernels/benchmarks/coremark/build/coremark-riscv32-npc.bin -m 0 --no-progress`: GOOD TRAP，`cycles=390482073`、`CPI=1.285`、branch miss `2458726`、branch accuracy `95.8%`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 无。
- `risk_assessment`: local predictor 增加状态表，host 仿真频率略降；后续若追求仿真速度，需评估表规模或用统计开关做 A/B。

## 下一步建议

1. 若继续压 BPU，可增加 local/gshare/chooser 分项统计，判断 strong-local 覆盖是否仍有误伤。
2. 当前 DCache miss/writeback 仍固定在 `944075/7712384` 量级，下一轮更适合做 2-way/victim cache 或 miss-side burst，而不是继续扩 direct-mapped 容量。
3. 若追求硬件 PPA，需恢复 Yosys/STA 工具链后评估 local 表面积与时序影响。

## 收尾结论

- `final_result`: BPU local-history 优化已落盘并通过验证；后续用户要求的弱跳转初值也已落盘并通过回归。
- `evidence_summary`: branch miss 从用户基线 `3429214` 降至 local-history 后约 `2457500`；弱跳转初值补充后为 `2458726`，相对用户截图 `2457499` 基本中性略负，CPI 仍为 `1.285`。
- `notes`: 第一次 cpu-tests 未显式传 `AM_HOME` 时只是在构建层 include `/Makefile` 失败；补 `AM_HOME` 后 38/38 PASS。
