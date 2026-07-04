# BranchResolve — 分支误判判定

**文件**:`src/core/execute/BranchResolve.hh` · **↔ npc**:`OooDirectBranchResolveGate`

## 职责
纯组合 `*Gate`:比较分支的实际方向/目标与取指时的预测,判定是否误判 + 给出正确重定向 PC。
squash 本身属 `CpuTop`(control glue);本 gate 只做**判定**。

## 状态
无(纯组合)。

## 接口
- `Result resolve(pc, br_target, pred_next_pc, actual_taken)`:
  - `actual_next = actual_taken ? br_target : pc+1`;
  - 返回 `{mispredict = (actual_next != pred_next_pc), redirect_pc = actual_next}`。

## 不变量 / 行为
- 与 `ref_model` 的控制流语义一致:BRANCH 目标 = imm(绝对下标),条件 cond 0=EQ/1=NE。
- 误判时 `CpuTop::resolve_branch` 调 `Bpu::update` 训练预测器,再 `squash_after(redirect_pc)`。

## 测试
`tb_modules::test_execute`:not-taken 命中(不误判)、taken 与预测不符(误判 + 正确目标)。
