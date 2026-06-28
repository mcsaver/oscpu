# 评估系统的元评估(level-2:评估评估本身)

> 用户明确要求"评估评估本身,甚至评估评估的评估,三层为上限"。本文是 level-2:批判性审视
> `eval/npc-eval.sh` 度量了什么、**漏测了什么**,以校准"核已全绿/已到优化平台期"这一结论的可信边界。
> level-1(评估自校验)已内建于脚本(dummy smoke + 逐测试 CPI |Δ|>20% 漂移检测)。

## 1. 评估当前覆盖(level-1)
| phase | 度量 | 强度 |
|---|---|---|
| module TB(iverilog) | 112 项单模块定向 | 单元级,白盒断言 |
| riscv-tests | 271 官方指令回归(tohost) | 指令级黑盒 |
| AM cpu-tests + CPI | 56 系统测(ebreak GOOD TRAP)+ 加权 CPI | 系统级 + 性能 |
| difftest | 33 计算/整数访存逐指令对照 NEMU | **指令级架构等价(最强)** |
| benchmarks | CoreMark/Dhrystone | 真实代码性能 |

## 2. 盲点(level-2 的核心产出,按风险排序)
- **B1【正确性·高】difftest 不覆盖 Sv39/PMP/trap 指令级**:difftest 有意只跑 M-mode 计算子集,因 NEMU
  HW-A/D 与本核(非 Svadu、PMP 默认拒绝 S/U)**有意不同**。后果:**我本战役投入最多的复杂特性
  (PMP、Sv39 A/D、特权/trap)只被 GOOD-TRAP 粗粒度验证,未指令级对照**。GOOD TRAP 只说"最终没崩",
  不保证中间架构状态逐拍正确——这是"全绿"信心的最大缺口。
- **B2【正确性·中】module TB 覆盖率未量化**:112 TB 项 vs 146 个 RTL 文件;本战役新增的大量前端 gate
  小模块(`OooBranch*Gate`、`OooFetch*Gate` 等)多依赖系统级测试传导覆盖,无专属单元 TB。某些只在
  特定时序触发的模块级 bug 可能不在 271+56 中显现。
- **B3【性能·中】CoreMark 从未在 RTL 仿真跑完**:40+ 分钟孤儿进程,已杀。真实代码性能画像只靠
  Dhrystone(1.52)+ AM 微测加权(1.26);**缺工业标准 CoreMark**,AM 微测对真实负载的代表性存疑
  (加权 CPI 被 branch-resolve-loop 占 25%,偏微基准)。
- **B4【性能·中】时序不在 --all 回环**:Fmax 是独立手动 Vivado 流程。一个改动可能升 CPI 却悄悄劣化
  Fmax(反之亦然),`--all` 不自动抓时序回归。spec-B 实验正是手动跨两套度量才看清 trade。
- **B5【方法·低】CPI 加权代表性**:加权基于 AM PASS 子集,非真实负载分布;跨版本可比但绝对值勿过解读。

## 3. 对"优化平台期"结论的校准
"核全绿(112/271/56 + difftest 33/33)、CPI 1.26、易得红利收割完"**成立但有边界**:
- 性能结论**可信**(CPI 多路交叉验证 + 自校验防漂移)。
- 正确性结论**有缺口**:复杂特性(PMP/Sv39/trap)未指令级验证(B1)。"全绿"= 通过了现有 gate,
  **不等于** PMP/Sv39 路径无潜伏 bug。

## 4. 可执行改进(按性价比,重定向下一步迭代)
1. **闭合 B1(最高值,低风险)**:扩 difftest 到**不发散**的 trap/CSR M-mode 路径(M-mode ecall/mret、
   mtvec/mepc/mcause/mstatus 读写、非法指令 trap),这些 NEMU 与本核语义一致,可指令级对照。
   再评估是否值得让 NEMU 对齐本核 PMP/非-Svadu 语义以覆盖 Sv39/PMP(NEMU 改动,中风险)。
2. **闭合 B3**:给 CoreMark 设迭代数/cycle 上限跑完一次,或测 iterations/sec 外推,补真实代码数据点。
3. **闭合 B4**:把 `vivado/run-synth-module.sh <关键模块>` 的 logic-levels 纳入 `--all` 可选 gate
   (内存安全的模块级,非整核),自动抓时序回归。
4. **量化 B2**:列出无专属 TB 的模块,补关键路径模块的单元 TB。

## 5. level-3(评估元评估,点到为止——三层上限)
本元评估自身的风险:**可能高估 B1**。反驳:difftest 排除 Sv39/PMP 是**经过根因分析的有意决策**
(NEMU 语义确实不同,见 `difftest.cpp` 注释与 ROADMAP),不是疏漏;且 PMP/Sv39 已有
riscv-arch-test + AM 系统测 + 定向单测(sv39-ad-bits 等)多重把关,只是非"逐指令"级。故 B1 是
"信心边界"而非"已知 bug"。**结论:B1 值得闭合以升级信心,但不应据此判定核有缺陷**。三层到此为止,
避免在元-元-元的思辨上空转。

## 6. 变更记录
- 2026-06-28:建立 level-2 元评估,识别 5 盲点(B1 difftest 不覆盖 Sv39/PMP/trap 为最高风险),
  据此把下一步迭代从"高风险性能 surgery"重定向到"低风险正确性验证加固"(扩 difftest M-mode trap/CSR)。
