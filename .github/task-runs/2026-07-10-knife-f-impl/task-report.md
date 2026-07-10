# 任务报告：刀 F 实施——fetch hit 融合拍（1 包/拍收复）

spec：`npc/rv64/design/arch/knife-f-fetch-hit-fusion.md`（同日冻结+落地回填）。
侦查：`.github/task-runs/2026-07-10-knife-f-recon/`。

## 1. 结果

| 指标 | 刀 F 前 | 刀 F 后 |
| --- | --- | --- |
| CoreMark CPI | 1.633 | **1.206（-26%，0xfcaf GOOD TRAP）** |
| CoreMark cycles | 5254589 | 3881109 |
| WNS @100MHz | -5.59 | -5.69（时序中性，0.10ns 扰动带） |
| 等待源 | fetch 90.8% | fetch 86.9% / mem 66.7% / branch_flush 16.8% |

**两刀累计（刀 X+刀 F）：CoreMark CPI 3.280 → 1.206（-63%）**，收复了 CPI 考证
归因的 MUL 迭代化（+1.76）与 SRAM 化 fetch 吞吐减半（+0.50）两大项。
距 F2 后峰值 0.93 的残差 ≈0.28：mem 侧拍数（SRAM 化 +1、刀 M +1）+刀 B+分支惩罚。

## 2. R1 风险实测触发与修复（本刀最有价值的过程资产）

首版融合拍 WNS -5.59→-6.73（劣化 1.14ns，超退出条件阈值 0.5ns），top10 违例
全族 = SQ snoop_head → fetch 桥（lkp_inv_q / payload SRAM addr / first_beat CE）。

根因：融合拍使 fire（发射决策）依赖 `cache_hit_w`，而 hit 判定含**窗口②当拍
invalidate 地址比较**——跨模块 store 失效链（SQ→顶层→fetch 桥→cache）被提升为
取指发射关键路径，驱动 ready/fire/SRAM addr/一整片锁存 CE。

修复（`0ce6d0222`）：
1. cache 新增 `lookup_hit_no_snoop_o`（hit 判定去掉窗口②项），融合臂 =
   no_snoop hit && `!invalidate_valid_i`（**单 bit 关断**）——invalidate 撞判决拍时
   融合降级、走精确寄存路径（S_RESP，+1 拍）。正确性：inv_valid=0 时两式相等，
   inv_valid=1 时融合关闭 ⇒ **fusion⇒精确 hit 恒成立**，被失效包绝不经融合臂交付。
2. `lkp_inv_q` 去 CE 无条件锁存——CE=fire（含 hit 锥）与 D=snoop 比较在 CE-mux
   上的串联被切断；非 fire 拍锁到的值因 dec_en_q=0 不被消费，语义等价。

修复后 WNS -5.69（收回 1.04ns）、CoreMark CPI 1.206（降级臂零代价——invalidate
拍占比小）。

**方法论沉淀**：融合类优化把"判定"提升为"发射决策"时，判定锥的每条输入链
（尤其跨模块 snoop/失效/仲裁类）都会连带提升为发射关键路径——设计拍要按输入链
逐条审查，低频精确性条件用单 bit 降级臂隔离，把精确比较留在寄存路径里。

## 3. 验证

- 桥 focused TB 定向用例：hit 1 拍口径、融合拍 back-to-back 连发、rsp 反压落
  skid（S_RESP）、miss 拍 ready=0、invalidate 拍融合降级（数据不损）、同 window
  失效杀 hit（AR 重取不交付 stale 包）；mutation（ready 放宽到 miss 拍）被
  "miss beat not ready" 用例逮住→复原绿。
- module TB 86/86、lint 双变体、check-contract 32≥20。
- riscv-tests 177/177（含特权套件）、AM 全 PASS、CoreMark 0xfcaf（两轮：
  融合初版 1.207 / 时序修复后 1.206）。
- 全状态 difftest 按用户策略仍留重构整体收口。

## 4. 下一步观察

- 等待源新格局：fetch 86.9% 仍最大但 mem 66.7% 升至第一顺位竞争者、
  branch_flush 16.8%、hazard 15.9% 回升（fetch 供给变快后依赖等待重新显形）。
  下一刀候选：mem 侧（load hit 3 拍/桥串行 2 拍节拍——刀 M 逆向的吞吐收复）
  或分支惩罚（redirect 后 3-4 拍取指重启空窗）。按数据点单。
- 剩余 fetch 等待的构成（86.9% 仍高）：taken redirect 重启空窗×flush 频率 +
  FIFO 信用反压——fetch-time BPU（F2 遗留清单）是根治项。
- 方案 C（对齐 8B 窗口取指）保留为中期结构选项。
