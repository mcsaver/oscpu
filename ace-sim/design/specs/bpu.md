# Bpu — 分支方向预测器

**文件**:`src/core/frontend/Bpu.hh` · **↔ npc**:`OooBranchDirectionPredictor`

## 职责
bimodal 方向预测:PC 索引一张 2-bit 饱和计数器表(PHT)。取指拍组合查询,分支解析拍写回。

**gshare(⑤,`ghist_bits>0` opt-in)**:全局历史寄存器 GHR ^ PC 索引 PHT(捕获分支间相关性);`update` 移入实际方向。
默认 `ghist_bits=0` = bimodal(旧版本行为不变)。GHR 解析拍更新(非投机,只影响预测/时序,不改架构结果)。
调用/返回的返回目标预测见 [ras](ras.md)。

## 状态
- `bht_`:`vector<uint8_t>`,每项 2-bit 计数器(0..3),初值 1(弱不跳转)。

## 接口
- `bool predict(pc)`:组合读端口,`bht_[pc % size] >= 2` 即预测 taken。
- `void update(pc, taken)`:写端口,按实际方向饱和 ±1。

## 不变量 / 行为
- 无 cur/next 分离:BHT 在解析拍(Wakeup)写、取指拍(Eval)读;phase 序 Wakeup < Eval,
  故同拍同 PC 的 update 先于 predict 生效 —— 与迁移前单体行为逐位一致。
- 预测**只影响性能,绝不影响架构正确性**:误判由 `BranchResolve` + `CpuTop::squash_after` 纠正。

## 测试
`tb_modules::test_Bpu`:初值不跳转 → update(taken) 后跳转 → 饱和 → update(not-taken) 回落。
