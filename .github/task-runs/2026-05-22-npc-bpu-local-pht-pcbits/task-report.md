# Task Report

## 基本信息

- `task_id`: `2026-05-22-npc-bpu-local-pht-pcbits`
- `task_slug`: `npc-bpu-local-pht-pcbits`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-22`
- `updated_at`: `2026-05-22`

## 任务目标

- `source_request`: 用户提供弱跳转初值后的 CoreMark/NPC 复跑截图。
- `goal`: 解释该结果，并继续基于 top miss PC 优化 BPU。
- `scope`: `BranchPredictor.v`、`tb_branch_predictor.sv`、项目记忆。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | AGENTS、memory、NPC study README | 当前 BPU/DCache 状态 | 已读取必读链 |
| analyze-result | codex | completed | 用户截图、CoreMark 反汇编 | 弱跳转初值中性，local PHT alias 仍明显 | `core_state_transition` 多 PC 低位别名 |
| rtl-derive | codex | completed | `BranchPredictor.v` local predictor | local PHT 混入更多 PC 位 | 本文件“RTL 推导摘要” |
| implement | codex | completed | RTL 与单测 | local PHT 1024 -> 4096，新增 alias 单测 | 文件修改 |
| ab-test | codex | completed | strong-local/valid-local 两种 mux 策略 | valid-local 变差，保留 strong-local | CoreMark A/B |
| verify | codex | completed | 最终 RTL | testbench/lint/build/CoreMark/cpu-tests 通过 | 见“验证证据” |
| record | codex | completed | 本轮结论 | memory 与 task-run 更新 | `.github/memory/project-status.md`、`.github/memory/modules/npc.md` |

## RTL 推导摘要

### 阶段 1 - 需求

- 功能目标：减少 CoreMark 热点分支在 local predictor 中的 PHT alias，尤其是同一字符状态机里的多个静态分支。
- 端口边界：不改变 `BranchPredictor` 外部端口，不改变 IF 预测和 EX 更新握手。
- 性能约束：预测仍为 IF 阶段组合查表；更新仍在 `update_valid_i && update_is_branch` 时训练。
- out-of-scope：本轮不新增 loop predictor、chooser、流水 payload 或 cache 改动。

### 阶段 2a - 协议规则

- `predict_valid_i` 有效时并行读取 gshare、local history、local PHT、BTB 和 RAS。
- local PHT index 从旧 `{pc[2:1], local_history}` 改为 `{pc[4:1], local_history}`。
- local PHT valid/counter 的更新仍只在 resolved branch 上发生；local history 使用更新前 history 索引 PHT，再移入实际方向。
- cold/weak local 不覆盖 gshare；只有 local counter 为 `00/11` 强置信时覆盖。

### 阶段 2b - 状态机

- 本轮没有新增 FSM。
- reset：local history 清零，local PHT valid 清零，counter 初始化为 weak taken。
- predict：组合形成 12-bit local PHT index，强置信 local 方向 mux 到最终 branch 方向。
- update：resolved branch 饱和更新 local PHT，并更新 per-PC local history。

### 阶段 2c - 不变量

- local PHT index 宽度为 `BPU_LOCAL_PHT_PC_BITS + BPU_LOCAL_HISTORY_W = 12`，访问范围固定在 4096 项内。
- local/gshare counter 仍保持 `0..3` 饱和值域。
- local weak/cold 不得覆盖 gshare，避免有效但不稳定的 local 项反向污染整体预测。
- gshare 继续使用预测阶段携带到 EX 的 `update_bht_idx_i` 更新，不改变精确上下文训练。

### 阶段 2d - 数据通路约束

- 新增 PC 位通路：`predict_pc_i[4:1]` / `update_pc_i[4:1]` 进入 local PHT index。
- 保持 local history 通路：`pc[8:1] -> local_hist_q`，history 宽度仍为 8。
- branch 方向 mux 保持：`local_strong ? local_taken : gshare_taken`。
- 关键路径变化：local PHT 从 1024 项扩大到 4096 项，组合读仍与 gshare 并行，最终只进入一个小 mux。

## 验证证据

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-bpu-local-pht-pcbits-final-tests run`: 21/21 PASS。
- `make -C npc/single lint`: PASS。
- `make -C npc/single -j14`: PASS。
- `./npc/single/build/NpcSimTop am-kernels/benchmarks/coremark/build/coremark-riscv32-npc.bin -m 0 --no-progress`: GOOD TRAP，`cycles=389956180`、`CPI=1.283`、branch miss `2196215`、branch accuracy `96.2%`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS。
- A/B：local valid 直接覆盖 gshare 后 CoreMark 为 `cycles=390099474`、branch miss `2267352`，差于 strong-local 覆盖，已还原。

## 收尾结论

- `final_result`: local PHT 去别名优化已落盘并通过验证。
- `evidence_summary`: 相对用户截图 `cycles=390481207`、branch miss `2458726`，最终降到 `cycles=389956180`、branch miss `2196215`。
- `risk_assessment`: PHT 表项从 1024 增至 4096，硬件面积和仿真状态增加；后续 PPA 闭环需要补综合/STA。
