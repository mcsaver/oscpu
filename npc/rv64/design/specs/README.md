# 模块规范索引（design/specs/）

按子系统组织的逐模块规范。★ = 专业规范(图文并茂、状态机、不变量、关键路径、验证);
其余为 decompose 阶段的简明 owner 边界笔记(见 `../../vsrc/README.md` 总览)。
模板见 `../arch/SPEC-TEMPLATE.md`。动 RTL 前先写/更新对应 spec。

> **2026-07-11 authority 刷新**：当前实现快照为
> `../arch/rtl-ground-truth-2026-07-11.md`；2026-07-03 全量重审快照已移入
> `../arch/history/rtl-ground-truth-2026-07-03.md`（已归档）。07-11 先校正当前
> authority 与承重合同，不把一次性“已审计份数”继续作为现状正确性指标。
>
> **2026-07-03 全量重审历史**：随全 RTL 从零重读，
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
- Integer full-WB 与 EX-only fast broadcast 的独立完成/消费边界：`ooo-longop-fast-broadcast.md`；
- Integer MEM completion formal-only、依赖 N+1 消费：`ooo-mem-formal-only.md`；
- FP 簇现状:`vsrc/execute/OooFpBackend.v` 为真源(实施方案与旧 pending 壳 spec 已归档);
- FP 入口 ready DAG 与双 lane 原子接收：`ooo-fp-admission-credit.md`；
- FP completion 到整数 IQ 的跨域 sticky wake：`ooo-cross-domain-wakeup.md`；
- Integer completion 到 FP IQ/read8 的全 sticky 时序边界：`ooo-int-to-fp-sticky-wakeup.md`；
  `ooo-fp-arith-gate` — FP short arithmetic 5-cycle 流水、B-FP launch/out 与 macro/OOC decision contract;
  `ooo-fp-reg-file` — 架构 FPR(commit 双写+trap 恢复源)

## 访存 / MMU
- ★ `ooo-mem-axi-bridge-fsm` — 访存桥 FSM(probe/pretrans/nokill/store 解耦/单 outstanding)
- ★ `ooo-data-word-cache` — 数据侧 8B line D-cache 语义、debug/common checker 与 macro/OOC 前置合同
- ★ `ooo-sv39-tlb` — Sv39 TLB(64 项/上下文/superpage)
- ★ `pmp-checker` — PMP 检查器(16 项 TOR/NA4/NAPOT)
- `yosys-macro-boundary-contracts` — Yosys 四黑盒宏/OOC 边界合同（timing/area/语义缺口与任务清单）
- `ooo-memory-access`(wrapper)〔`ooo-pending-memory-sequencer` 已 B4 物理删除 → `history/`〕
- LSQ 现状:SQ(4)+probe/drain+store→load 前递已落地,LQ/MSHR/多 outstanding 未做
  (见 current snapshot §2/§4；实施方案已归档 `history/ooo-lsq-implementation-plan.md`)
- HW A/D 当前语义由 `ooo-fetch-axi-bridge` 与 `ooo-mem-axi-bridge-fsm` 承载；一次性实施
  计划 `history/ooo-sv39-hw-ad-update.md` 已归档。IFU partial-write flush-drain 已于
  2026-07-12 关闭；PTE write PMP 边界仍在 active spec 开放。

## 取指 / 前端 / 分支预测
- ★ `ooo-fetch-axi-bridge` — 取指桥(ITLB+硬件 PTW+硬件 A update+取指包 cache+PMP；
  IFU A-update flush-drain 与 page-fault byte provenance 已关闭；精确 physical access/tval 与
  PTE-write PMP 合同仍开放)
- ★ `ooo-fetch-packet-cache` — 取指包 cache 语义、debug/common checker 与 macro/OOC 前置合同
- `ooo-fetch-packet-*`、`ooo-fetch-pc-outstanding-sequencer`、`ooo-fetch-request-mux`、
  `ooo-frontend-*-gate`、`ooo-fetch-head-*-gate`
- 活预测件:`ooo-branch-direction-predictor`(gshare+局部混合，含 debug/common checker 与 macro/OOC 前置合同)、`ooo-direct-*`、`ooo-ras-*`、
  `ooo-branch-bpu-update-gate`(issue-resolve 单源)、`ooo-branch-resolve-recovery-gate`、
  `ooo-backend-drain-tracker`
- 已 B4 物理删除(spec 归档 `history/`,历史证据见 07-03 已归档 snapshot §4):`ooo-pending-branch/jump-sequencer`、
  `ooo-pending-control-resolve-gate`、`ooo-branch-prefetch-*`、`ooo-branch-target-cache-control-gate`、
  `ooo-jalr-prefetch-status-gate`、`ooo-fetch-packet-hit-mux`
- ⚠️ 保留死码(融合活+死/门控死臂,模块存活未删):`ooo-branch-spec-tracker`(checkpoint 死,RAS 压制副作用仍活)、
  `ooo-branch-append-dispatch-gate`(BRANCH_APPEND_DISPATCH_ENABLE=0)、`ooo-branch-bpu-update-gate`(旧四臂删,issue-resolve 单源存活)
- F2 真预测现状见 current snapshot §3(实施方案已归档)

## 控制面 / 提交 / CSR
- ★ `ooo-flush-redirect-contract` — **flush/redirect 契约（现状冻结 v1）**：E1-E13 源总表(源×[清|保持])+优先级全序(年龄律)+三铁律核对+INV-1..5 承重不变量(立即断言草案)+C-OBJ-REDIR 单点仲裁器重写裁决(assert-then-converge)。触碰 flush/redirect/stall/序 的改动的前置契约（依据 decisions [38] + 宪法 §7 C7）。
- ★ `ooo-csrfile` — CSR(M/S/U 特权/trap-return/委托/PMP/satp/counters)
- `ooo-control-plane`、`ooo-commit-output-mux`、`ooo-csr-*-mux`、`ooo-pending-system-sequencer`、
  `ooo-pending-trap-exit-sequencer`、`ooo-stop-pending-sequencer`(域 B 仅剩 system/trap 类)、
  `ooo-trap-exit-*`、`ooo-pending-dispatch-arbiter`、`ooo-pending-lane1-capture-gate`
- 〔`ooo-synthetic-lane1-ret-sequencer`(+CommitGate) 已 B4 物理删除 → `history/`〕

## 装配 / 总线
- `ooo-core-top-glue`、`ooo-writeback`、`ooo-control-plane`、`ooo-memory-access`(子系统 wrapper)

## 说明
- 整体架构见 `../arch/ooo-core-architecture.md` 与
  `../arch/rtl-ground-truth-2026-07-11.md`(CURRENT snapshot)；流程/优先级见 `../arch/ROADMAP.md`。
- **归档区**:`history/`(spec 与一次性实施方案)、`../arch/history/`(arch 过程文档),
  各自 README 有逐份归档原因与现状参考。
