# MulDiv — 乘除单元

**文件**:`src/core/execute/MulDiv.hh` · **↔ npc**:`OooMulDivUnit`

## 职责
乘法与除法;持 MUL、DIV 两个独立功能单元(各自 latency/II/width)。

## 状态
- `mul_`、`div_`:两个 `FunctionalUnit`(默认 MUL lat=3/II=1/width=2,DIV lat=20/II=20/width=1 非流水)。

## 接口(按 `is_div` 路由到对应 FU)
- `can_issue(is_div,c)` / `reserve(is_div,c)` / `next_free(is_div)` / `latency(is_div)`。
- `compute(is_div,a,b)`:mul = `a*b`;div = `b ? a/b : 0`(除零 → 0,与 ref_model 一致)。

## 不变量 / 行为
- DIV 非流水(II=20 = latency):同一 DIV 完成前不接受下一个;结构冒险由 `CpuWake` 兜底
  (`II>latency` 的漏唤醒 = V1 审查缺陷 #2/5/9,此处 II==latency 天然被完成事件兜底)。
- 多周期完成:发射拍 `reserve` + 算结果放进 `FuComplete` 事件 payload,`+latency` 周期后到期。

## 测试
`tb_modules::test_execute`:mul=42、div=5、div-by-0=0、latency(div/mul)=20/3。
