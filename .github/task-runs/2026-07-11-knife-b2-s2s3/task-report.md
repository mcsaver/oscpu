# 任务报告：刀 B2 完整落地（S1.5 实验→回退→S2 主刀→S3 收口）

用户指令："一路做到 S3"。spec §6/§7 已回填全程。

## 核心结果

**CoreMark CPI 1.064 → 0.877（-17.6%），越过 F2 后峰值 0.93**——taken 分支从
"flush 事件"降格为"顺序流地址选择"的根治目标达成。性能战役总账：
考证起点 3.280 → **0.877（-73%）**。

## 过程记录

1. **S1.5 实验失败与回退**（本轮最贵的学费）：lookup 挪 enqueue 次拍+FIFO 补写
   +fill-bypass 三轮迭代，accuracy 恒 78.4%（-10.2pp）；探针实锤表热/回训正常，
   判为 GHR 采样点错位类精度稀释。**BPU lookup 时点=精度敏感点，勿再动**（已进
   spec/memory）。
2. **S2 主刀**（22 文件，委托实施）：断融合改流/分支 fire 死化/E4 去 branch/
   K1 退役/截断位 facts 单点门控/哨兵消灭。**捎带抓出预存潜伏 bug**：IntBackend
   独占族 slot 分派不同源→MMIO 事务丢失死锁（S2 相位变化暴露幸存者偏差）。
3. **S3**：difftest 全绿（riscv 177/177+CoreMark 零 mismatch）+86/86+contract 34。
4. **STA 遗留**：WNS -15.37——融合拍控制前缀（dcache→direct fire→redirect→
   fetch fire→判决单拍贯通）+B2 的 pred 判决叠加。**移交独立战役**（fetch 前端
   拍界重划：方案 C 对齐取指/redirect 全次拍化/BPU SRAM 化三选）。

## 账面

| 指标 | 值 |
| --- | --- |
| CoreMark CPI | **0.877**（accuracy 85.6%，-3pp GHR 错位质量债） |
| difftest | riscv 177/177+CoreMark 零 mismatch |
| module TB / lint / contract | 86/86 / 双变体零告警 / 34 |
| WNS | -15.37（时序债独立立项） |
