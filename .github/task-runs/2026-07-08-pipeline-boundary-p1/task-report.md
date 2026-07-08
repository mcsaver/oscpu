# 任务报告：级间边界治理 P1——EX→WB 第一刀（ex0/ex1 簇 → PipeStageReg）

## 目标

按 `design/arch/pipeline-stage-boundary.md` §4 P1：把全核唯一真实 stage 寄存簇
（`OooIntBackend` ex0/ex1，145b×2 lane）提取为 `PipeStageReg #(.WIDTH(144))` 实例，
功能模块退化为"纯组合 + 写入下一级寄存器"的目标形态。

## 实现者人格

- `OooIntBackend.v`：14 根 `exN_*_q` reg → 2 个 PipeStageReg 实例（valid 由原语持有）
  + 12 根 `_q` wire 位段别名（下游 wb mux 零文本改动）；原 always 各赋值臂等价改写为
  组合 `assign`（ex0 三臂/ex1 单臂；fire/muldiv/clmul 限定词被 up_valid 吸收）；
  与之共用 always 块的 mem_pending/AMO FSM 一行未动。
- payload 位段（144b/lane 两 lane 一致）：`{rob_idx[143:140], pdest[139:134],
  result[133:70], exception[69], cause[68:64], tval[63:0]}`。
- 端口契约（均带注释）：`flush_i ← flush_i||checkpoint_restore_i`（原 flush 臂等价）、
  `kill_i ← 1'b0`（现状：ROB-walk kill 不清 EX→WB，晚到 wb 由 ROB squash 吞）、
  `down_ready_i ← 1'b1`（ROB wb 口恒收）。
- 原"未命中臂写全 0 payload"语义放弃（valid=0 拍留脏）——逐点核对无 valid=0 读
  payload 消费点，且全仓 grep 确认 ex0_*/ex1_* 无模块外 XMR/DPI 引用。
- filelist：`RTL_PIPE_STAGE_REG` 进 `RTL_CORE_SRCS`；testbench `TB_OOO_INT_BACKEND_SRCS`
  接入（7 个大节点 TB 自动获得）。spec §4/§8 同刀更新。

## 验证证据（全绿）

| 护栏 | 结果 |
| --- | --- |
| focused TB tb_ooo_int_backend | PASS（-DOOO_ASSERT，PSR 断言使能） |
| 全量 module TB | **85/85 PASS**（含 tb_pipe_stage_reg 与 7 个复用大节点 TB） |
| verilator lint | PASS（-Wall 零告警） |
| check-contract | PASS（断言计数 12→17，本刀 +2 = PSR-HOLD/PSR-FLUSH-EMPTY） |
| core-regress（主控收口补跑） | **overall_rc=0**（riscv-tests 177/177 含特权 + AM + build） |

## 审查者人格

- 语义等价性靠"表达式原文迁移 + up_valid 吸收限定词"论证 + 全量 TB/tohost 回归背书；
  未做形式等价证明（工程上以现行护栏为准）。
- **既有 lane 不对称记录在案**（非本刀引入、原样保留）：ex1 的 exception 不被 sq_fwd
  压 0，ex0 的 sq_fwd 臂 exception 恒 0——若 sq_fwd 与 mem_exception 同拍为真两 lane
  行为不同。已在 RTL 注释与 spec §8 标注，是否加固待用户裁决。
- down_ready≡1/kill≡0 是现状语义的如实映射，不是原语能力上限——未来 wb 仲裁反压或
  kill 语义变更时只改端口连线。
- 全状态 difftest 按用户策略继续推迟。
