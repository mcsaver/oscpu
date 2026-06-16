# Task Report

## 基本信息

- `task_id`: `2026-05-29-ooo-jalr-btb-prefetch`
- `task_slug`: `ooo-jalr-btb-prefetch`
- `graph_template`: `rtl-regression-debug-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-29`
- `updated_at`: `2026-05-29`

## 任务目标

- `source_request`: 用户追问 OoO 为什么没有真正的 JALR BTB 预测器，以及 OoO 是否和原 BPU 冲突，并要求学习原有 BPU 后在 OoO 复用或达成相同功能。
- `goal`: 在 OoO 实验前端中补上普通 JALR 的 BTB target 预测能力，并让仿真顶层统计反映真实 hit/miss。
- `scope`: 仅实现普通 JALR target BTB 与影子预取；保留现有 RAS return 快路径和 branch 静态方向预测。

## RTL 四段式推导

### 1. 需求与边界

- 普通非 RAS return JALR 需要 PC-tagged target BTB，不能再只是统计为 miss。
- BTB 命中可提前取目标 packet，但不能在真实 target resolve 前进入 dispatch FIFO。
- RAS 直接返回路径保持原有保守条件，避免把 `jalr rd/rs1` 复杂 hint 误当可直接提交的 return。
- 仿真统计仍通过 `NpcSimTop` 层次化只读观察，不新增 core 端口 ABI。

### 2. 协议、不变量、状态机

- lookup：`pending_jump_q && pending_jump_jalr_q` 且不是 RAS 已覆盖的 return 时查 JALR BTB。
- prefetch：BTB 命中只发一个 shadow fetch，请求/响应复用现有 `branch_prefetch_*` 影子槽。
- promote：resolve/drain 时 `branch_prefetch_pc_q == real_target` 才把影子包转正为 FIFO entry。
- discard：预测错误或 no-link JALR hit 后同拍 redirect 打出的重复 response 走 `discard_fetch_rsp_q` 丢弃。
- 不变量：不绕过 drain，不修改 ROB/IQ/rename 提交顺序，不让错路 fetch packet 暴露给 dispatch。

### 3. RTL 数据通路

- `OooAluFetchCore.v` 新增 direct-mapped `jalr_btb_valid_q/pc_q/target_q`。
- `pending_jump_resolve_ready_w` 时用真实 `pending_jump_resolved_target_w` 训练 BTB。
- `branch_prefetch_req_valid_w` 从 branch-only 扩展为 branch 或 JALR BTB hit。
- 新增 `jalr_prefetch_*` match/hit/pending wires，分别处理 no-link commit 和 linked JALR drain completion 的 shadow promotion。
- `NpcSimTop.sv` 用 `pending_jump_jalr_btb_hit_w` 作为 `npc_bpu_lookup_event` 的 BTB hit，并把 JALR shadow hit 合入 OoO prefetch hit 画像。

### 4. 验证与证据

- `make -C npc/single/testbench run TESTS=tb_ooo_alu_fetch_core`: PASS。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4`: PASS。
- `hello-str`: GOOD TRAP，`BTB JALR lookup=hit 6, miss 1`。
- `recursion`: GOOD TRAP，`BTB JALR lookup=hit 212, miss 6`。
- CPU-test 全量：`40/40 PASS`，`cycles=64582/commits=78679/weighted CPI=0.820829`，结果表 `/tmp/ysyx-ooo-full-cputests-jalr-btb.tsv`。
- 三类代表：最高 `dummy (46/12/CPI=3.833333)`，最低 `crc32 (8676/16305/CPI=0.532107)`，近平均 `leap-year (1377/1692/CPI=0.813830)`。
- 非 OoO `make -C npc/single NPC_OOO_ALU_EXPERIMENT=0 -B -j4`: PASS。
- 最终 `NPC_OOO_ALU_EXPERIMENT=1 -B -j4`: PASS。

## 根因与修复点

- 根因：OoO 宏路径绕开了顺序核 `IfStage/BranchPredictor`，普通 JALR 只有 drain 后用 `rs1+imm` 解析目标，没有预测期 BTB lookup/target prefetch。
- 冲突结论：不是和 BPU 冲突，而是两条前端路径互斥；OoO 路径没有实例化原 BPU。
- 本轮修复：在 OoO 前端内部达成原 BPU 的 JALR BTB target 功能等价，并继续通过仿真顶层层次化引用统计。

## 风险与限制

- 当前没有把原 `BranchPredictor` 的 gshare/local BHT 动态分支方向迁入 OoO；Branch/Direction 统计仍描述当前 OoO 静态 BTFNT 方向预测。
- JALR BTB 只隐藏目标 packet 取指延迟，不提前提交或提前执行普通 JALR 后的目标路径；完整控制投机仍需要更细粒度 checkpoint/rollback。
- no-link JALR shadow hit 后的同拍 redirect duplicate response 目前用 discard 丢弃，正确性已闭合，但仍可能浪费一次 fetch 事务。

## 收尾结论

- `final_result`: OoO 现在有真实普通 JALR BTB target 预测/影子预取路径，BTB lookup hit/miss 统计也来自真实 OoO predictor hit。
- `evidence_summary`: `hello-str` 与 `recursion` 的 BTB hit 已非零，全量 CPU-test 40/40 PASS。
