# RV64 OoO 核 性能优化前置：基线核查与回归分诊（2026-06-28）

## 背景
用户目标：按核评估报告做性能优化迭代。按 `npc-optimization-workflow`，性能改动前必须确认 CPU-test 全量绿。
核查当前工作树基线时发现 AM cpu-tests 回归，遂转入分诊。

## 基线测量
- 工具链：Verilator 5.020 / iverilog / riscv64-unknown-elf-gcc，均可用。
- 二进制新于源码，非陈旧；core RTL（排除 sim/legacy）0 个 initial/DPI。
- OoO 容量（define.v）：dual-issue，PRF 64，ROB 16，IQ 8，Fetch FIFO 4。容量模块参数化干净（无硬编码深度，无字面量覆盖宏）。

## 权威正确性 gate：**绿**
- 官方 `riscv-tests`（rv64ui/um/uc/uzba/uzbb/uzbc/uzbs + 特权 mi/si）：**271 PASS / 0 FAIL**（log: scratchpad/official_riscv3.log）。
  - 含 rv64mi-p-*（机器陷阱/CSR/中断）、rv64si-p-wfi/csr/dirty/ma_fetch（监管陷阱/wfi）全过 → 核 ISA + M/S 特权陷阱/中断投递基础**健全**。
- 结论：核在权威 gate 上正确性绿；可据此安全做性能优化。

## AM cpu-tests：46/56 PASS，10 项回归（平台层）
注意：加权 CPI 含超时项无意义；PASS 子集加权 CPI≈3.20（待优化对照基线）。

10 项失败全部在**特权/MMU/中断/平台设备模型**层，计算类全过。分诊：

| 测试 | 现象 | 性质判定 |
|---|---|---|
| sv39-ad-bits | BAD TRAP code=1(指令access fault)@s_entry | **测试/设计错位**：测试期望 HW A/D 自动更新(像 NEMU)，本核有意 A=0→fault。非 core 回归 bug；瑕疵是产生 access-fault(1) 而非更标准 page-fault(12) |
| sv39-ras-relocate | BAD TRAP code=2 | 待查：RAS/SATP relocation 边界 |
| sbi-timer | 卡 pc=0x800002c0(mret) 无限 trap 循环 | **CLINT timer 路径**：疑 mtip(mtime≥mtimecmp)持续置位/mtimecmp 写未生效，叠加 CLINT_MTIME_DIVISOR=10 |
| sbi-base-console / counteren-time / sbi-ipi-reset-hsm | 跑到周期上限(提交数千万) | 疑同 CLINT timer/中断簇 |
| linux-handoff / linux-mini-boot | 跑到周期上限 | 疑同簇 + 更长路径 |
| plic-sirq / uart-plic-sirq | 提交~35 条后野跳 pc=0x0 永久 spin | **PLIC MMIO 外中断路径**：trap redirect target 异常 |

## 关键定位证据
- 回归**不在用户未提交的 decompose 重构里**：HEAD(330071465 拆分前 OooAluFetchCore.v)同样失败 → 回归在更早提交历史，且不在近期回归网（近期只跑 riscv-tests+module TB，未含 AM 平台测试）。
- CLINT 分频：`vsrc/core/NpcTop.v:159 CLINT_MTIME_DIVISOR=32'd10`（记忆载明为修 systemd ttyS0 getty timeout 而加），`vsrc/bus/AxiLiteClint.v` mtip_irq_o=(mtime_q>=mtimecmp_q)。
- 与 Linux 目标的张力：timer 簇修复若简单回退分频到 1，可能回退 systemd/Linux 适配——需可兼容的真正修复，不能症状级回退。

## 结论与建议
- 核心在权威 gate 绿；10 项 AM 失败是**平台设备模型/timer 速率/MMU A/D 设计**层的既有漂移，部分是有意 Linux 改动的副作用，非近期重构引入。
- 候选根因簇：①CLINT timer 中断(8 项里的 timer/SBI/linux 多数)；②PLIC MMIO 外中断(2 项)；③MMU A/D 设计错位(sv39-ad-bits)；④RAS/SATP(sv39-ras-relocate)。
- 下一步取决于用户：深修平台回归(可能触碰 Linux 改动) vs 在绿 primary gate 上先做性能优化、平台回归单列 known-issue 跟踪。

---

## 修复结果（2026-06-28，全部已验证）

最终：riscv64-npc AM cpu-tests **56/56 PASS**，官方 riscv-tests **271 PASS/0 FAIL**（含 PMP/特权）。基线转绿。

1. **AM `abstract-machine/am/src/riscv/npc/trm.c`：_trm_init 配 PMP**（NAPOT 全空间 RWX，pmpaddr0=-1/pmpcfg0=0x1f）。根因：`PmpChecker.v` 末分支 `fault=(priv!=M)&&access`——PMP 已实现且无匹配条目时 S/U 一律拒绝(规范正确)；AM 测试进 S-mode 前不配 PMP，故首条 S 访问 access fault，陷入 M<->S 反复 trap。修复后 9 项 S-mode 测试(sv39-ras-relocate/counteren-time/sbi-*/plic-*/linux-*)转绿。CLINT 10:1 分频是红鲱鱼。
2. **`vsrc/frontend/OooFetchAxiBridge.v`：取指 cache PMP 性能修复**（关键）。原 `cache_hit_w=cache_hit_raw&&!pmp_active` + `fill=!pmp_active&&...` 使 PMP 一活动就整体禁用取指包 cache → 每次取指退到慢速 AXI → CPI 近 2x（真实 Linux/OpenSBI 永远配 PMP）。改为命中时按 PMP-grant 门控(`!req_exec_pmp_fault&&!req_exec1_pmp_fault&&(!paging||itlb_hit)`)，fill 恒开。A/B(同配 PMP)：add 2052→1086 cyc、matrix-mul 22094→8508 cyc、crc32 CPI 1.516→0.587，计算类完全回到无 PMP 水平；riscv-tests 271/0 不变。访存桥(OooMemAxiBridge)无此问题、data cache 一直正常。
3. **`am-kernels/.../tests/sv39-ad-bits.c`：SW 管理 A/D handler**。核非 Svadu，A=0/写且 D=0→page fault；测试改为 fault 时给叶子 PTE 置 A|D 再 mret 重试(仅 cause12-15)，HW-A/D 实现下 handler 不触发，两类实现通吃。

注：riscv64-nemu 在本环境无法构建(NEMU vga.o 警告当错误,既有问题)，sv39-ad-bits NEMU 可移植性未能本地复验，但改动保守。
