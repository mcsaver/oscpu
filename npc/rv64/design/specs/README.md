# 模块规范索引（design/specs/）

按子系统组织的逐模块规范。★ = 专业规范(图文并茂、状态机、不变量、关键路径、验证);
其余为 decompose 阶段的简明 owner 边界笔记(见 `../../vsrc/README.md` 总览)。
模板见 `../arch/SPEC-TEMPLATE.md`。动 RTL 前先写/更新对应 spec。

> **2026-07-03 全量重审**:随全 RTL 从零重读(真相基线 `../arch/rtl-ground-truth-2026-07-03.md`),
> 对全部 85 份文档逐份审计:**6 CURRENT / 67 DRIFT_FIXED(已校正) / 12 归档**。
> 对应死硅/死通道的活模块 spec 均已在标题下加 ⚠️ 状态注记(模块仍编译实例化,功能被
> 编译期常量或结构性不可达证死,拆除计划见宪法 §8.3)。归档件见 `history/README.md` 与
> `../arch/history/README.md`。

## 执行 / 调度 / 重命名（OoO 后端核心）
- ★ `ooo-muldiv-unit` — 整数乘除(radix-4+CLZ 算法图示)
- ★ `ooo-int-issue-queue` — 发射队列(压缩程序序/2 唤醒/2 oldest-ready)
- ★ `ooo-rename-alloc` — rename/free-list/busy-table/dispatch 分配链
- ★ `ooo-rob` — 重排序缓冲(2-wide 程序序提交/精确异常/ROB-walk 恢复)
- ★ `ooo-phys-reg-file` — 物理寄存器堆(写-读旁路/write1>write0/x0)
- ★ `ooo-rename-map` — 重命名映射(同拍 RAW/WAW 前递/walk 还原)
- `ooo-execute-backend`、`ooo-clmul-unit`
- FP 簇现状:`vsrc/execute/OooFpBackend.v` 为真源(实施方案与旧 pending 壳 spec 已归档);
  `ooo-fp-reg-file` — 架构 FPR(commit 双写+trap 恢复源)

## 访存 / MMU
- ★ `ooo-mem-axi-bridge-fsm` — 访存桥 FSM(probe/pretrans/nokill/store 解耦/单 outstanding)
- ★ `ooo-sv39-tlb` — Sv39 TLB(64 项/上下文/superpage)
- ★ `pmp-checker` — PMP 检查器(16 项 TOR/NA4/NAPOT)
- `ooo-memory-access`(wrapper)、`ooo-pending-memory-sequencer`(⚠️ 证死待删)
- LSQ 现状:SQ(4)+probe/drain+store→load 前递已落地,LQ/MSHR/多 outstanding 未做
  (见真相基线 §2.3/§3.3;实施方案已归档 `history/ooo-lsq-implementation-plan.md`)

## 取指 / 前端 / 分支预测
- ★ `ooo-fetch-axi-bridge` — 取指桥(ITLB+硬件 PTW+取指包 cache+PMP;SMC 失效缺口见 known-issues #111)
- `ooo-fetch-packet-*`、`ooo-fetch-pc-outstanding-sequencer`、`ooo-fetch-request-mux`、
  `ooo-frontend-*-gate`、`ooo-fetch-head-*-gate`
- 活预测件:`ooo-branch-direction-predictor`(gshare+局部混合)、`ooo-direct-*`、`ooo-ras-*`、
  `ooo-branch-bpu-update-gate`(issue-resolve 单源)、`ooo-branch-resolve-recovery-gate`、
  `ooo-backend-drain-tracker`
- ⚠️ 死硅家族(mode=1/domain-A 证死,已逐份注记):`ooo-pending-branch/jump-sequencer`、
  `ooo-pending-control-resolve-gate`、`ooo-branch-prefetch-*`、`ooo-branch-target-cache-control-gate`、
  `ooo-branch-spec-tracker`(checkpoint 死,RAS 压制副作用仍活)、`ooo-branch-append-dispatch-gate`、
  `ooo-jalr-prefetch-status-gate`
- F2 真预测现状见真相基线 §2.4(实施方案已归档)

## 控制面 / 提交 / CSR
- ★ `ooo-csrfile` — CSR(M/S/U 特权/trap-return/委托/PMP/satp/counters)
- `ooo-control-plane`、`ooo-commit-output-mux`、`ooo-csr-*-mux`、`ooo-pending-system-sequencer`、
  `ooo-pending-trap-exit-sequencer`、`ooo-stop-pending-sequencer`(域 B 仅剩 system/trap 类)、
  `ooo-trap-exit-*`、`ooo-pending-dispatch-arbiter`、`ooo-pending-lane1-capture-gate`
- ⚠️ `ooo-synthetic-lane1-ret-sequencer`(设计路径死)

## 装配 / 总线
- `ooo-core-top-glue`、`ooo-writeback`、`ooo-control-plane`、`ooo-memory-access`(子系统 wrapper)

## 说明
- 整体架构见 `../arch/ooo-core-architecture.md`(宪法 v0.2)与
  `../arch/rtl-ground-truth-2026-07-03.md`(现状真相基线);流程/优先级见 `../arch/ROADMAP.md`。
- **归档区**:`history/`(spec 与一次性实施方案)、`../arch/history/`(arch 过程文档),
  各自 README 有逐份归档原因与现状参考。
