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
- **B2【正确性·中】module TB 覆盖率(已量化,结论:良好)**:实测 113 个 TB 目标,**82/104 Ooo 模块
  有专属单元 TB(~79%)**,加 legacy/infra(ALU/CSR/LSU/cache/AXI)全覆盖。27 个缺专属 TB 的 Ooo 模块
  多为:① 集成 wrapper(OooExecuteBackend/OooFrontend/OooMemoryAccess/OooControlPlane——由子模块 TB +
  系统测覆盖);② 系统级已充分激励(OooMulDivUnit 经 div/mul+OOC综合、OooRvcDecompressor 经 compressed
  测且现已 difftest 逐指令、OooSv39Tlb 经 sv39-* 测)。真正值得补单测的少数=预测器组件
  (OooJalrBtb/OooRasStack/OooReturnContBuffer/OooBranchDirectionPredictor/OooPredictorUpdateGate),
  但预测器是性能特性非正确性(预测错只是慢,不影响架构正确,由 resolve-recovery 兜底),优先级低。
  **结论:覆盖率良好,无重大正确性缺口**。
- **B3【性能·中】CoreMark 跑完不可行→改用窗口 CPI(已闭合)**:CoreMark 完整迭代在 RTL 仿真不可行
  (10 迭代 >20min/>300M cycle 仍未完;仿真速度 <250K cycle/s)。**但 CPI 与迭代数无关**:用 50M-cycle
  上限窗口测得 **CoreMark CPI ≈ 1.020**(cycles=50M/commits=49.04M)。这是最佳真实代码 CPI
  (计算/循环密集、分支可预测,双发射 OoO 充分发挥)。真实代码画像现完整:CoreMark 1.02 < AM 加权 1.26
  < Dhrystone 1.52。
- **B4【性能·中】时序不在 --all 回环(已闭合)**:原 Fmax 是独立手动 Vivado 流程,改动可能升 CPI 却
  悄悄劣化 Fmax。**已加 `--timing` 模式**:Vivado 模块级 OOC(内存安全)综合关键模块取 Logic Levels
  作 Fmax 代理,把时序回归检测纳入评估系统(默认 OooDispatchBackend,基线 39 级)。
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

## 7. B1 闭合进展(2026-06-28 实测)
对候选 M-mode 测做了逐指令对照实验(建 difftest 核跑,内存安全):
- **新增 7 个逐指令 PASS**(difftest 覆盖 33→40):compressed(RVC)、fence-i、branch-fallthrough-save、
  **mem-test、ooo-mem-order(访存序)**、switch、stdio-format。把这些特性从仅-GOOD-TRAP 升级到指令级架构等价。
- **2 个发散,已 root-cause = 参考模型差异(非核 bug)**:
  - `misa-priv`:mismatch 在 `csrrs x8,misa,x0`。核 MISA=`0x...14112d`(A,C,D,F,I,M,S,U=**RV64GC+SU 正确值**);
    NEMU MISA=`0x...141106`(B,C,I,M,S,U,有 B 缺 A/D/F)→ **NEMU misa 配置与核 ISA 不符,核正确**。
  - `char-test`:发散在串口 MMIO 路径(NEMU 与核对 UART 寄存器建模不同)。
- **结论**:B1 最高风险盲点调查后,**可达逐指令路径未发现核 bug**;两处发散都是 NEMU-vs-核有意/配置差异。
  "核全绿"信心据此**上调**(40 测逐指令等价,含访存序)。剩余真盲点(Sv39/PMP 指令级)需让 NEMU 对齐
  核的非-Svadu/PMP 语义才能覆盖(NEMU 改动,中风险,价值低于已完成项,留作后续)。

## 6. 变更记录
- 2026-06-28:建立 level-2 元评估,识别 5 盲点(B1 difftest 不覆盖 Sv39/PMP/trap 为最高风险),
  据此把下一步迭代从"高风险性能 surgery"重定向到"低风险正确性验证加固"(扩 difftest M-mode trap/CSR)。
- 2026-06-28:执行 B1 闭合(§7):difftest 33→40 逐指令;misa-priv/char-test 发散 root-cause 为参考模型差异非核 bug。


## 8. FP 验证根使能器(下一会话路径,2026-06-28 调查)
当前 FP 验证靠 ① riscv-tests rv64uf/ud(静态舍入为主)② 13 项硬件 FP ASM smoke(`--fpsmoke`,逐值)。
**根使能器 = FPR-difftest**(difftest 比对 FPR/fcsr 对照 NEMU softfloat),能系统性逐指令验证所有 FP op
(含 FP#2 FMA 双舍入)。调查确认其为**多部件 infra 改动**:加 `debug_fprs_o` 总线(OooFpRegFile→
OooCoreTopGlue→NpcCoreTop→NpcTop→cpu-exec commit event)+ `difftest.cpp` DiffContext 加 fpr[32]/fcsr +
**NEMU regcpy ABI 加 fpr**(触碰敏感的 gpr/pc/fpr ABI——difftest 恢复史正卡于此)。**因触碰敏感 difftest ABI,
评估为需专注新会话**(配 Berkeley TestFloat 向量),非极深会话低风险小修。届时 FPR-difftest 就位后,
FP#2(FMA fused 重写)可逐位验证再实施。

**[2026-06-28 实测确认 FP 验证的根障碍]**:尝试"硬件 FP 结果经 fmv.x.d 进 GPR→现有 GPR-difftest 对照 NEMU"的轻量路径,实测 difftest 在第一条 FP 指令即 control-flow mismatch(NEMU ref pc→0=trap)。根因:**NEMU 参考 misa=B,C,I,M,S,U 无 F/D**(见 §7 misa-priv),NEMU 把 FP 指令当非法 trap、根本不执行 FP。故**任何 FP-difftest(GPR 或 FPR 路径)都先需 NEMU 重配 F/D 支持**(misa 加 F/D + 启用 softfloat FP 执行 + 不 trap FP),这是 FP 验证使能器的**前置硬障碍**,必须新会话处理。当前 FP 验证仍靠 riscv-tests rv64uf/ud(NEMU 编译这些时另配?实际 rv64uf/ud 通过说明核 FP 至少过官方静态-rm 向量)+ 13 项硬件 FP ASM smoke(逐值,不依赖 NEMU)。


## 9. FP 验证已解锁(2026-06-28 突破,超越 §8 评估)
§8 评估"FPR-difftest 需新会话"被本轮**推翻**:发现 NEMU 有 F/D 支持(Kconfig `RISCV_EXT_F/D` + `inst/fp.c` softfloat)
但 difftest 参考默认关→FP 指令被 trap(即 §7 misa-priv 中 NEMU misa 无 F/D 的根因)。**仅需启用
`CONFIG_RISCV_EXT_F/D`(riscv64-npc_defconfig)重建 .so** 即解锁 FP-difftest——无需 FPR 比对 infra:
硬件 FP 结果经 `fmv.x.d` 进 GPR,现有 **GPR-difftest** 即可逐指令对照 NEMU softfloat(新 `fp-difftest-probe.c`)。
验证:difftest 40→41 全过(整数不受影响 + FP add/sub/mul/div/sqrt/FMA finite 对照 NEMU)。
**两个 NEMU 参考局限(非核 bug,限定 FP-difftest 用法)**:
- **NEMU 非规范 NaN**:NEMU softfloat 传播输入 NaN payload,核按 RISC-V 输出规范 qNaN(0x7ff8...);
  实测 NaN 输入 op 分歧(核对、NEMU 非规范)→ **FP-difftest 须用有限非-NaN 操作数**。
- (misa B vs A/D/F 等已知,§7)。
**成果**:FP 正确性(有限操作数)现纳入 difftest 系统验证;FP#2(FMA 双舍入)经此**确认**(见 known-issues)。
