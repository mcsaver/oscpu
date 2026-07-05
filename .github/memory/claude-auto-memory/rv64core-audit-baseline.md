---
name: rv64core-audit-baseline
description: npc/rv64 OoO 核的权威现状入口(2026-07-03 全 RTL 重读真相基线)+ 历史审计要点
metadata: 
  node_type: memory
  type: project
  originSessionId: 76369d5c-65e7-46d2-ae43-bf343854733a
---

**查 rv64 核现状的唯一权威入口(2026-07-03 起)**: `npc/rv64/design/arch/rtl-ground-truth-2026-07-03.md`
(全 RTL 无文档依赖重读的真相基线: 能力/缺口/死硅普查/参数表, 全带 file:line 证据;
证据全文 `.github/task-runs/2026-07-03-rv64-rtl-reread-audit/report-*.json` + answers.json)。
分析该核时**先读基线再对照代码**, 不要信旧记忆/旧文档的图景。

**2026-07-03 重读后的核心图景**(取代本记忆旧版"两执行域六类串行"描述):
- RV64IMAFDC+Zb*, M/S/U+Sv39(硬件 PTW×2)+PMP16, 2-wide OoO(ROB16/IQ8+8/PRF64+64/SQ4/MIQ4)。
- 域 B(stop_pending+全 drain)只剩 system/trap/IRQ 类; branch/jump(F2)/fp(FP 簇)/mem(SQ+LSQ P2/3)
  已迁域 A; **pending_mem 被形式化证明从未可达**。mode=1 恒 mispredict 时代已结束(F2 真预测生产化)。
- 死硅普查成表(基线 §4): pending 三链/dispatch 快解析族/BTC/JALR-BTB 更新/prefetch 全家/
  checkpoint 五套影子/SyntheticLane1Ret/RedirectArbiter(未编译)/PRF 5 无效读口/RAS 宏16 vs 实32。
- **原 4 项硬正确性缺口(known-issues #111) —— 2026-07-03 批已修 3.5 项, 仅 #3B 单列**:
  ①SMC: **#3A 8B store 足迹漏失效已修**(same_fetch_window +3→+7 + 邻域补 p4/p6, packet cache 模块 TB
  证否, 提交 700c9e894); **#3B fence.i 真 flush 单列待落地**——覆盖"投机越过 fence.i 已入 ROB 的年轻改写
  指令"(#3A 只失效 cache 管不到已取入 ROB 的项), 需 CTRL_BUS_W 扩宽 + 复制 sfence pending_system 提交路径
  共 6-8 模块、与 #3A 部分冗余、无测试可验实际行为、fence.i 罕用故 perf 影响小, 设计推荐评估后单做
  ——**这是当前唯一剩余的已知正确性缺口**。
  ②Sv39 跨页 misaligned **已修**(OooIntBackend:1094 精确异常 + 定向 cpu-test, 提交 82eaa68e6)。
  ③difftest RVC MMIO skip **已修**(difftest.cpp:182 用 next_pc, 提交 fece978e6)。
  ④unsupported 域 B trap 出口 **已修**(classify unsupported_residual=ctrl_legal&&!NEED_EXEC→arch_trap
  head0 精确出口, 对当前 ISA 恒 0 结构零回归, 提交 700c9e894)。
- **合规批(§3.2)已全修**: wfi-TW(mstatus.TW=1&priv<M 的 WFI illegal)/zb-overwide(REV8 收 0x35、删 OP 域
  zext.h)提交 ed96f679e; frm-DYN(classify 拿 committed frm 判 DYN+reserved-frm illegal, frm_i 贯穿前端)提交 700c9e894。
- difftest 盲区不变: 只比 GPR+PC, 不比 CSR/FPR/内存。
- 文档体系已释放重建: 85 份逐审(67 校正/12 归档到 design/{arch,specs}/history/), 宪法升 v0.2
  (E2/E3 已消除、branch_event 有显式 mispredict、SQ 已建), 死硅 spec 全带 ⚠️ 注记。

**历史要点保留**(2026-06-30 会话, 详见 project-status): F1/F6-F11 正确性修复已提交;
legacy 删除; LR/SC 活锁(#106)/mnstatus(#107) 已修; 回归套件 RV64GC 全集。
工具坑: 跑回归必须 `export NPC_HOME=.../npc/rv64`(见 [[rv64-regress-howto]])。

详见 [[rtl-coding-standard]] [[ooo-core-architecture-constitution]] [[coremark-mode1-spec-wrongpath]] [[rv64-regress-howto]] [[f2-true-branch-prediction-landed]] [[lsq-sq-switch-landed]] [[fp-cluster-eleven-root-causes]]。
