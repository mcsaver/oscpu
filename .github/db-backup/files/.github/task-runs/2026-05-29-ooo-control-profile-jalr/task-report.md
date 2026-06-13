# Task Report

## 基本信息

- `task_id`: `2026-05-29-ooo-control-profile-jalr`
- `task_slug`: `ooo-control-profile-jalr`
- `graph_template`: `npc-sim-regression`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-29`
- `updated_at`: `2026-05-29`

## 用户约束

- 正确性高于优化；RTL 性能改动必须先通过 CPU-test 全量。
- 优化不能只看 `add`，必须从同一次全量结果选 `highest_cpi`、`lowest_cpi`、`near_average_cpi` 三类样本共同分析。
- 深水区优化要从整体角度看：OoO 后端、fetch/cache bridge、AXI crossbar、LSU、提交口和仿真统计边界都要纳入全局瓶颈图。
- 继续遵守一个 Verilog/SystemVerilog module 一个源文件。

## RTL 推导摘要

- `需求`: same-cycle demand miss AR 后，全量加权 CPI 为 `0.870428`，高权重样本 `recursion` 仍有 `pending_jump` 大量 stop cycle；需要先补统计证明瓶颈，再做低风险语义等价优化。
- `协议`: no-link 非 return JALR 的精确边界是后端已 drain 后读取架构 GPR 计算目标，且指令为 `jalr x0, rs1, imm`、不是 RAS return、不写 rd、不修改 RAS；misalign trap、call、return、普通写回 JALR 仍走原路径。
- `状态`: 新增 `pending_jump_nolink_w/pending_jump_nolink_commit_w`，在 pending jump resolve ready 且 commit ready 时清前端 pending/FIFO/outstanding，设置 `ctrl_commit_*` 合成一条无写回控制提交，并把 `next_fetch_pc_q`/redirect fetch 指向解析目标。
- `不变量`: 该路径只在 backend drained 后触发，避免读到未退休 GPR；只处理 `rd=x0`，所以不产生架构寄存器写回；`pending_jump_return_w` 排除 RAS return，不提前 pop RAS；目标 bit0 非法仍触发 `EXC_INST_ADDR_MISALIGN`。
- `全局尝试`: 曾尝试让 fetch bridge 在 R0 返回同拍发 AR1，并让 `AxiDpiSlave` 支持 R dequeue + AR enqueue；编译暴露 `UNOPTFLAT` ready/valid 组合环，根因是 `AxiLiteXbar` 当前 `rd_master_busy/rd_active` 将同一 master/slave 读事务串行化。该尝试已撤回，后续必须连同 xbar read completion/grant 协议一起重构。

## 变更清单

- `npc/single/vsrc/ooo/OooAluFetchCore.v`
  - 增加 no-link 非 return JALR 直接合成提交/redirect 快路径。
  - 该快路径从 `jump_dispatch_valid_w` 中排除，避免再送后端空往返。
- `npc/single/vsrc/sim/NpcSimTop.sv`
  - 增加 `npc_ooo_cycle_event` DPI 调用，观察 OoO retire/execute/dispatch/fetch/control/mem 事件。
- `npc/single/csrc/cpu/cpu-exec.cpp`
  - 增加 OoO pipeline 统计输出。
  - 保留双提交事件逐条处理，每条 commit 带提交后 GPR 快照，避免 lane0 difftest 被 lane1 未来写回污染。
- `.github/instructions/npc-optimization-workflow.instructions.md`
  - 固化深水区全局瓶颈排序：除三类必选样本外，还要按 cycles、excess cycles、cache miss、control/LSU/AXI wait 决定模块级优化方向。

## 代表样本与全量结果

- `baseline_full_tsv`: `/tmp/ysyx-ooo-full-cputests-samecycle-ar.tsv`
- `baseline_weighted_cpi`: `0.870428`
- `final_full_tsv`: `/tmp/ysyx-ooo-full-cputests-final.tsv`
- `final_weighted_cpi`: `0.865293`
- `final_total`: `cycles=68083`, `commits=78682`, `pass=40/40`

| sample_kind | test | cycles | commits | CPI | key_profile |
| ----------- | ---- | ------ | ------- | --- | ----------- |
| `highest_cpi` | `dummy` | 52 | 12 | 4.333 | 极短程序，固定启动/冷 miss 成本主导，权重很小 |
| `lowest_cpi` | `prime` | 2760 | 5158 | 0.535 | 高吞吐样本，retire 2-wide 周期占主导，接近目标 |
| `near_average_cpi` | `shift` | 472 | 323 | 1.461 | 混合冷 I-miss、D-load miss 与 branch wait；代表短中等样本 |
| `high_weight_reference` | `recursion` | 6372 | 4513 | 1.412 | no-link JALR 命中后从 `6744` cycles 降到 `6372` cycles |

## 验证结果

| command_or_test | result | evidence |
| --------------- | ------ | -------- |
| `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4` | PASS | Verilator build clean |
| representative `dummy/prime/leap-year/recursion` | PASS | 均 GOOD TRAP；`recursion` 从 `6744` 降到 `6372` cycles |
| representative `shift` | PASS | `472/323/CPI=1.461`，OoO profile 已采集 |
| CPU-test full final | PASS | `40/40 GOOD`, weighted CPI `0.865293`, TSV `/tmp/ysyx-ooo-full-cputests-final.tsv` |
| fetch R0+AR1 overlap experiment | REVERTED | Verilator `UNOPTFLAT`，xbar read busy/active 串行化导致组合环风险 |

## 结论

- `final_result`: 保留 OoO 画像统计与 no-link 非 return JALR 快路径；不保留 fetch/xbar 同拍 AR1 尝试。
- `impact`: 全量加权 CPI `0.870428 -> 0.865293`，收益较小但全量正确；高权重 `recursion` 控制流收益明确。
- `next_steps`: 继续从全量贡献排序出发，优先评估 xbar/read refill 协议、line-based I-cache 或多 outstanding/LSQ，以及 branch/ret checkpoint 投机。目标 `CPI=0.5` 仍未完成，goal 保持 active。
