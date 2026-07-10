# 任务报告：时序战役 T1+T2+T4 全落地（T3 维持否决）

用户指令："整个 t1-4 全部执行后进行仿真测试和综合"。T3（wb→issue 前递禁 mem 源）
维持否决——全部 load 依赖 +1 拍的 CPI 代价(估 +0.3~0.5)会吐掉性能战役大半成果。

## 时序结果（真弧口径，100MHz）

| 阶段 | WNS | TNS | top 路径 |
| --- | --- | --- | --- |
| S0 真弧基线 | -7.49 | -69409 | dcache rdata→…→resolve→fetch SRAM（三刀贯通链） |
| T1+T2+T4 后 | **-6.98** | **-59194(-15%)** | SQ snoop→fetch SRAM（贯通链已切断，top 换人） |

## CPI 代价（CoreMark 10 迭代，全绿 0xfcaf）

| 阶段 | CPI | 增量 |
| --- | --- | --- |
| T 前基线 | 1.038 | — |
| T1（resolve 次拍取指） | 1.063 | +0.025 |
| T1+T2（刀 D 融合 tie-0） | **1.206** | **+0.143（超预估一倍——K1/T1 改变分支时序后 load 链暴露度上升）** |

## T4 的最大价值：BPU update 57ns 隐藏结构债曝光

OOC 实测：FpArithGate setup 2.782/clk2q 0.633、BPU lookup clk2q 1.447 已真值化
回填 lib。**BPU update(in→reg) 实测 57.0ns**（4096 项 FF 阵列写 decode+双表串联，
ABC lev 30 压不动）——黑盒占位弧一直藏着这条债，未写进 lib（会淹没全核 STA），
**修复需独立刀：BPU 表降容/SRAM 化/update 流水化——这是全核真实 Fmax 的隐藏上限，
优先级应排最前**。

## 验证

module TB 86/86 + lint + riscv-tests 177/177（含特权）+ CoreMark difftest ON
零 mismatch 0xfcaf。config 已恢复性能配置。

## 决策建议

1. **T2 回滚观察**：+0.143 CPI 的代价与 T1 的时序贡献可能重叠（需 T1-only 单测
   综合实证）；tie-0 完全可逆。
2. **下一刀=BPU 57ns 债**（表降容/SRAM 化评估）。
3. SQ snoop→fetch SRAM 族（现 top）：snoop 链打拍评估。
