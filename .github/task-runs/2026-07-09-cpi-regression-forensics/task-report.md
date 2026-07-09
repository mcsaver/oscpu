# 考证报告：CoreMark CPI 0.78→3.28 飙升归因（2026-07-09）

用户问"CPI 为什么从 0.8 飙升到 3.1"。三路取证（历史时间线 / fetch 侧 RTL / mem 侧 RTL）+
对抗交叉核验，归因链数值闭合（Σ ΔCPI = +2.50 = 3.280 − 0.783）。

## 0. "0.8" 的出处

`.github/memory/modules/am-kernels.md:47-48`：**2026-05-30 CoreMark CPI=0.783**（10 迭代，
cycles=2518692/commits=3216171；同日 1000 迭代完整跑 0.779）——历史峰值，当时核功能少。
7 月任何时点都未回到 0.8x：6-28 为 1.02（EVAL-REPORT），F2 真分支预测落地后（07-03）
最好 **0.93**（+18.3%，commit 926a2ef6d）。

## 1. 归因表（0.783 → 3.280，交叉核验后）

| 因素 | ΔCPI | 占比 | 证据强度 |
| --- | --- | --- | --- |
| **07-07~08 综合向重写：MUL 单拍组合乘→固定 64 拍迭代**（c11cc172a） | **+1.76** | **70%** | 中-强（区间归因+代码实锤+hazard 桶定量吻合） |
| **SRAM 宏化持久代价：fetch 吞吐 1→1/2 + load hit +1 拍**（78c7a1a1f） | **+0.50** | 20% | 强（1.157→0.966 差分） |
| 5-6 月功能净回退（Sv39/PTW/PMP/FP 等特性代价） | +0.147 | 5.9% | 弱-中 |
| P5 刀 M：load hit 2→3 拍（bdab6136d，有意时序换 CPI） | +0.083 | 3.3% | 强 |
| P5 刀 B：删 IQ bypass（fc655fa07，同上） | +0.007 | 0.3% | 强 |
| dcache write-update 丢失窗口 | 终态≈0（峰值+0.045，faba82262 已修复） | 0 | 强 |
| BPU 宏占位 | 0（未 SRAM 化，FF 阵列组合读 0-cycle 合同不变） | 0 | 强 |

## 2. 两个主因的机制

### MUL 64 拍迭代（+1.76，最大头）

- `npc/rv64/vsrc/execute/OooMulDivUnit.v:265` 附近：`mul_count_q <= 7'd64`，STATE_MUL_RUN
  每拍移位累加、**固定 64 拍无早退出、单 outstanding 阻塞**。改前为组合单拍
  `selected_prod = op1_ext * op2_ext`（c11cc172a^）。
- DIV 同提交反而做了 CLZ 定位 radix-4 早退出（"取代原 word 32 拍/dword 64 拍固定方案"）——
  **MUL 没享受同等优化**。
- CoreMark matrix 段乘法密集；MUL 动态占比反推 ≈2.7%（×63 拍 ≈ +1.7）。
- 定量印证：刀 M log timed 段 ooo_window 分解 **hazard 桶 51-55%**（最大等待源，
  依赖 MUL 结果的指令堵 IQ），hazard×CPI ≈ 1.7 拍/指令 ≈ 区间归因值。
- 该跳变落在 07-07~08 测量真空（"综合向 RTL 重写后无全量回归记录"），两端实测
  0.93（07-03）→ 2.69（07-08 上午，CoreMark/MHz 1.157 推算）。

### SRAM 宏化 fetch 吞吐减半（+0.50 主体）

- `OooFetchAxiBridge.v:474-478`：S_LOOKUP 判决拍不在 ready 集合，相邻 hit 的 SRAM
  lookup 无重叠 → **1 包/2 拍 = 前端供给上限 1 指令/拍 = 双发射需求的 50%**，
  单此一项 CPI 地板抬到 1.0+（icache hit 率 99.68%，瓶颈是吞吐非 miss）。
  改前 FF 阵列组合读 back-to-back 1 包/拍 = 2 指令/拍喂饱。
- 曾被误归因为"store 丢 write-update"（-16.5% 主因说）：**已被差分证伪**——07-09
  恢复 write-update 后 miss 139221→3770（-97.3%），CPI 却只收回 3.235→3.190
  （收回量仅 16.5pp 中的 8%）。fetch 吞吐减半（地板 +0.5）才与残差吻合。
- mem 侧同型：load hit 串行 2 拍/项（S_LOOKUP 拍禁 advance），mem 等待桶 19-20%。

## 3. 对 P5 排刀的含义（性能收复优先级）

1. **MUL 拍数优化收益（≈1.76 CPI）≫ 刀 F 等一切时序刀的代价总和**——radix-4/16 Booth
   迭代（64→16-32 拍）+ 窄操作数早退出（复制 DIV 的 CLZ 方案），或 2-3 拍流水阵列
   乘法器（宏化为综合边界，同 SRAM 思路）。综合目标（砍组合乘法巨锥）不必用 64 拍串行
   来买。
2. **fetch 吞吐收复（≈0.5 CPI）可并入刀 F**：S_LOOKUP 与下一请求的 SRAM 读重叠
   （真流水化 lookup），恢复 1 包/拍；比"再加判决拍"优先。
3. 等待源分解（ooo_window）已是现成决策仪表：timed 段 hazard 55%/fetch 46-49%/
   mem 19-20%/branch_flush 5%。

## 4. 证据与不确定项

- 时间线换算自洽性：CoreMark/MHz × CPI = 3.125~3.127（四个双打印点，0.06% 内一致）。
- 全部数据点出处（commit/log/文档行号）见 workflow 取证原文：本目录 `evidence/forensics.json`。
- 不确定项：MUL 动态占比 2.7% 为反推值无指令 mix 实测；0.93→2.69 区间内
  PmpChecker/INDEX_W/盲失效残余贡献未隔离（源码审查显示量级不足）；store 桥占用
  均摊 ±0.2 不确定带。定案级隔离实验（MUL 临时改回组合乘重测）未做——三重印证
  （代码实锤+区间差分+hazard 桶定量）已足回答归因，隔离实验的正确形态是直接做
  MUL 优化后看收复量。
