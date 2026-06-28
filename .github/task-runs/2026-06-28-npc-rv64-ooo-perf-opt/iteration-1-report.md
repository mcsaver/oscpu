# RV64 OoO 核 优化迭代 #1 报告（2026-06-28）

## 目标
按核评估报告做性能优化迭代：先修回归 → 再优化 → 重新审视 → 报告 → 继续迭代。

## 起点：基线核查发现回归
- 工作流要求"性能改动前 CPU-test 全量绿"。核查发现当前工作树 AM cpu-tests 46/56（10 项 S-mode/平台测试失败）。
- 经隔离 worktree + 官方 gate 确认：**核在权威 gate 绿**（riscv-tests 271/0、module 112/112、ACT4 PMP/Sv39），10 项失败在 AM 平台测试层，且**非未提交重构引入**（HEAD 拆分前同样失败，不在近期回归网内）。

## 已完成改动（全部已验证）

### A. 回归修复（基线转绿）
1. `abstract-machine/am/src/riscv/npc/trm.c`：`_trm_init` 在 M-mode 配 PMP（pmpaddr0=-1 NAPOT 全空间 / pmpcfg0=0x1f RWX）。根因：`PmpChecker.v` 规范性默认拒绝（PMP 已实现且无匹配条目 → S/U 拒绝），AM S-mode 测试不配 PMP → 进 S 即 access fault。修复 9 项。
2. `am-kernels/.../tests/sv39-ad-bits.c`：trap handler 改为软件管理 A/D（page fault 时置叶子 PTE 的 A|D 再 mret 重试，仅 cause12-15）。核非 Svadu、用 page-fault 软管 A/D；HW-A/D 实现下 handler 不触发，两类通吃。修复第 10 项。

### B. 性能优化
1. **`vsrc/frontend/OooFetchAxiBridge.v` 取指 cache PMP 修复（头号）**。原 `pmp_active` 一置位就整体禁用取指包 cache → 真实 Linux/OpenSBI(永远配 PMP)下取指永远 miss、退慢速 AXI、CPI 近 2x。改为命中按 PMP-grant 逐访问门控、fill 恒开。A/B(同配 PMP)：add 2052→1086、matrix-mul 22094→8508(CPI 2.465→0.949)。
2. **`vsrc/execute/OooMulDivUnit.v` DIV word 迭代减半**。word 除法只跑 32 次迭代(原 64，高半区恒 0 浪费)，可证明等价。收益：shuixianhua/prime/wanshu/goldbach/div/leap-year 各 -44~47%。
3. **撤回**：ROB16→32 + IQ8→16 扩容实测对全部样本零改善(部分微升)，按工作流撤回。证明本核瓶颈是执行延迟+串行 pending，非乱序窗口深度。

## 验证（改动后全绿）
- AM cpu-tests：**56/56 PASS**（修复前 46/56）
- 官方 riscv-tests（默认+特权）：**271 PASS / 0 FAIL**
- 模块 testbench：**112 / 112 PASS**

## 性能结果
AM cpu-tests 加权 CPI（全 PMP 配置，真实场景）：

| 阶段 | 加权 CPI | 总 cycles |
|---|---|---|
| 禁缓存基线 | 3.7427 | 548203 |
| + PMP 取指缓存修复 | 3.0910 | 452753 |
| + DIV word 优化 | **2.2908** | 339253 |
| **累计** | **-38.8%** | **-38.1%** |

## 重新审视：DIV opt 后新瓶颈（下一轮候选）
按 cycles 贡献：
1. `branch-resolve-loop` 68k（CPI 1.9）—— 分支误预测恢复 / 单级 spec checkpoint 串行（评估报告 🟠）。
2. `shuixianhua` 60k、`prime` 44k —— 仍 div 主导（radix-4 word 可再减半到 16 次迭代）。
3. `ooo-mem-order` 22k、单 entry pending memory 串行（评估报告 🔴，需 LSQ，重构量大）。

候选优化（按 ROI/风险）：
- **DIV radix-4**（word 16 迭代再减半）：中等改动、有 rv64um+AM 验证网、收益直接命中 #2 瓶颈。
- **branch-spec/redirect**：命中 #1 瓶颈，但触碰评估报告点名的脆弱 redirect if 链，风险较高、需先补定向 testbench。
- **LSQ/store-forward**：命中 🔴 串行访存，架构级重构，风险最高、收益面最广。

## 备注
- riscv64-nemu 在本环境无法构建（NEMU vga.o 警告当错误，既有问题），sv39-ad-bits 的 NEMU 可移植性未本地复验，但改动保守（handler 仅 page-fault 触发）。
- 改动文件：trm.c、sv39-ad-bits.c、OooFetchAxiBridge.v、OooMulDivUnit.v（define.v 已还原）。均未提交（用户决定提交时机）。
