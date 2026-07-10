# 任务报告：时序战役 S0——SRAM 真实时序弧接入 + 第一份可信 STA

## S0 完成项

- bsg_fakeram + 修改版 CACTI 编译落地（~/tools/bsg_fakeram，cfg=npc_sram.cfg，
  65nm 保守近似 55nm——CACTI 无 55 节点，65 偏悲观=安全方向）。
- CACTI 实测弧回填 gen_macro_libs.py（per-cell 时序表，端口表/lib 格式不动）：

| 宏 | clk-to-q | setup | 占位曾 | 失真 |
| --- | --- | --- | --- | --- |
| Sram4096x199 | **1.543ns** | **1.842ns** | 1.0/0.5 | setup 差 **3.7×** |
| Sram4096x113 | **1.285ns** | **0.763ns** | 1.0/0.5 | clk2q +29% |

- BPU/OooFpArithGate 保持占位（非 SRAM，真实化需 OOC 提取，留后续）。

## 第一份可信 STA（现有 netlist + 真弧，OpenSTA）

**WNS -6.05 → -7.49（真弧账 +1.44ns），TNS -69409。**

Top 路径解剖（全部 top10 同族）——**三把性能刀叠加缝成的全流水单拍贯通链**：
```
dcache SRAM rdata[87]（clk-to-q 1.285，真弧惩罚①）
→ dcache tag 比较 → hit（刀 D 融合谓词）
→ mem 桥 rsp_rdata 组合直出（刀 D rsp 组合臂）
→ IntBackend LSU 数据展开 → AMO gate → ex1 payload → wb1_data
→ PRF 写→读 bypass → issue1_src2 同拍前递
→ branch_compare1（分支在 EX 用刚 load 到的数据解析）
→ resolve redirect → fetch req fire（同拍 redirect 臂）
→ fetch packet cache SRAM addr（setup 1.842，真弧惩罚②）
```
每把刀单独时序中性/阈值内（刀 D +0.36、刀 F 0.10、K1 未单测），叠加成 17.5ns。

## 排刀选项（下一步决策材料，按打断点）

| 选项 | 打断点 | 时序收益 | CPI 代价 | 评估 |
| --- | --- | --- | --- | --- |
| T1 | resolve 类 redirect 改次拍取指（direct fire 保持同拍） | 砍链尾 ~2.5ns（redirect mux+fetch fire+SRAM setup 1.842） | mispredict penalty +1 拍（低频：8% 分支）≈+0.01~0.02 | **首选**：链尾贡献大、代价最小、改动小（redirect PC 寄存一拍） |
| T2 | 刀 D rsp 数据臂降级（load hit 数据寄存交付） | 砍链头 ~1.5ns | 撤刀 D（+0.066 回吐） | 保留为 T1 不够时的追加 |
| T3 | wb→issue 同拍前递对 mem rsp 源禁用（下拍 PRF 读） | 砍中段 | 唤醒延迟 +1 拍对全部 load 依赖链（大） | 代价过大，否决 |
| T4 | BPU/FpArithGate 真弧化 + 全核重综合（真弧驱动 ABC 优化目标） | 数字更准+综合器自动平衡 | 零 | 与 T1 并行做 |

## 方法学沉淀

**"每刀阈值内"不等于"叠加安全"**——三把刀各自通过 0.5ns 门禁，叠加造出新的
最长链。时序门禁应升级为"top 路径族语义审查"（本次路径的每一段都是某刀的
组合臂），不只看 WNS 数值。占位弧时代的所有 STA 结论需要用真弧重新校准
（幸而各刀的"换人/中性"判定方向未反转，只是量级低估）。
