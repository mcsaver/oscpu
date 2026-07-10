# 任务报告：BPU 57ns 债修复 + T2 回滚定案

## BPU 债修复（update 两拍流水 + BHT 4096→1024）

- update in→reg：**57.0ns → 1.46ns（MET）**——stage1 寄存输入+读老值（GHR 当拍），
  stage2 训练写表；back-to-back 同项 RAW 丢一次训练增量（启发式可容忍）；
  checker 参考模型/spec/宏合同门禁同步（next cycle→two cycles）。
- 流水化后内部 reg-to-reg **写扇出债显形 46ns**（upd_taken_q→4096 项 bht_q 的
  D 网络——1-bit 扇出 4096 的布线惩罚，非逻辑深度）→ **降容 1024**（idx 12→10）
  砍两级。CoreMark accuracy 92.0→88.7%（-3.3pp）但 **CPI 仅 +0.001**——降容无感。
- 残债记录：1024 项 FF 表的写扇出在无 buffer 树的粗糙综合下仍高（黑盒内不进全核
  STA）；真实后端 CTS/buffer 优化会大幅缓解；终极治本=BPU 表 SRAM 化（需 lookup
  两拍化=刀 B2 语境），暂不追。

## T2 回滚定案（综合性能账）

| 形态 | WNS | Fmax | CPI | 综合性能(f/CPI) |
| --- | --- | --- | --- | --- |
| T1+T2 | -6.98 | 58.9MHz | 1.206 | 48.8 |
| **T1-only（回滚，定案）** | -7.51 | 57.1MHz | **1.064** | **53.7（+10%）** |

T2 的 0.53ns 时序贡献买不回 0.142 CPI。回滚已生效（FUSION_EN=1 恢复），
tie-0 形态留档可随时重试（如 BPU SRAM 化后时序余量变化）。

top 路径回到 dcache rdata→fetch SRAM 族（T1 砍掉 resolve 臂后，剩余路径经
direct fire 同拍 redirect——K1 故意保留的高频预测收益，下一刀候选之一）。

## 验证

module TB 86/86 + riscv-tests 177/177（含特权）+ CoreMark 0xfcaf（CPI 1.064）。

## 下一步候选

1. SQ snoop→fetch SRAM 与 dcache rdata→direct fire→fetch SRAM 两族（现 top，-7.5）
2. fetch SRAM setup 1.842 的结构对策（写口 fill 路径打拍/方案 C 对齐取指）
3. 回性能线（刀 B2）或 SoC 对接
