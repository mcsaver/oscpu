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
- ★ `ooo-global-producer-no-live-reuse` — **v8l/v8v 全局 ProducerId holder census 与有限代际出生门合同**：
  字段级自动发现 19 个 full-P Q alias/holder（含 retire-resident LQ）、1 个显式组合 full-P
  reg 豁免、5 个
  ProducerId-bearing packed stage、12 个 owner-token Q 与唯一 ROB generation authority；
  Q-only complete mask、memory 原子交接、
  `GEN_W=1` 整圈回绕和 fail-closed checker 的静态入口为
  `make -C npc/rv64 check-producer-holder-census`，完整 focused/mutation 动态入口为
  `make -C npc/rv64 check-global-producer-no-live-reuse`。
  该 scoped 合同不提升完整架构或 PPA。
- ★ `ooo-muldiv-unit` — 整数乘除(radix-4+CLZ 算法图示)
- ★ `ooo-integer-longop-producer-lease` — **v8h MulDiv/CLMUL ProducerId 租约合同**：
  两个 singleton holder 贯通 full PID、Q-only full-lifetime lease、ROB exact-open 与
  `EX0 > EX1 > memory > MulDiv > CLMUL` 同拍 actual-claim；本地整数 long-op scope 已闭合，
  FP/branch/pending-system/CSR 与全核 no-live-reuse 仍 RED
- ★ `ooo-fp-producer-lease` — **v8i FP ProducerId 租约与双阶段完成授权合同**：
  FP IQ/issue/arith/exec1/long/done-FIFO 六类 holder 贯通 full PID/Q-only lease，FIFO token 建立
  跨周期 pending capability，result/formal 分离 exact-open/claim，并以精确 post-launch Q credit
  防不可背压结果溢出；branch/pending-system/CSR 与全核 no-live-reuse 仍 RED
- ★ `ooo-branch-resolve-producer-authorization` — **v8j registered branch-resolve full-PID 授权合同**：
  resolve q 与 EX0 同源 full PID、专用 cycle-free ROB query、生产态 coherence fail-closed；当前为
  contract-review 阶段，未形成 scoped GREEN 或 PPA 结论
- ★ `ooo-int-issue-queue` — 发射队列(压缩程序序/2 唤醒/2 oldest-ready)
- ★ `ooo-rename-alloc` — rename/free-list/busy-table/dispatch 分配链
- ★ `ooo-rob` — 重排序缓冲(2-wide 程序序提交/精确异常/ROB-walk 恢复)
- ★ `ooo-phys-reg-file` — 物理寄存器堆(stored-only 5R2W/write1>write0/x0)
- ★ `ooo-rename-map` — 重命名映射(同拍 RAW/WAW 前递/walk 还原)
- `ooo-execute-backend`、`ooo-clmul-unit`
- Integer full-WB 与历史 EX-only fast broadcast 的 T3B/T3G 切点：`ooo-longop-fast-broadcast.md`；
- Integer EX completion 的全 sticky / PRF stored-only 最终边界：
  `ooo-ex-sticky-wakeup-barrier.md`；
- Integer MEM completion formal-only、依赖 N+1 消费：`ooo-mem-formal-only.md`；
- FP 簇现状:`vsrc/execute/OooFpBackend.v` 为真源(实施方案与旧 pending 壳 spec 已归档);
- FP 入口 ready DAG 与双 lane 原子接收：`ooo-fp-admission-credit.md`；
- FP completion 到整数 IQ 的跨域 sticky wake：`ooo-cross-domain-wakeup.md`；
- Integer completion 到 FP IQ/read8 的全 sticky 时序边界：`ooo-int-to-fp-sticky-wakeup.md`；
- FP execution/load completion 到 FP IQ、FP-store 与四口 FP PRF 的全 sticky/stored-only
  边界，以及 exec1/long completion-arbiter 的 selective-kill-now 合同：
  `ooo-fp-sticky-wakeup-barrier.md`；
- backend drain 的 ROB-empty / core-retire-count 冗余消除：
  `ooo-drain-retire-redundancy.md`；
  `ooo-fp-arith-gate` — FP short arithmetic 5-cycle 流水、B-FP launch/out 与 macro/OOC decision contract;
  `ooo-fp-reg-file` — 架构 FPR(commit 双写+trap 恢复源)

## 访存 / MMU
- ★ `ooo-load-queue` — **v8v OOO-3 retire-resident Load Queue 合同**：
  16-entry shared full-ProducerId CAM 覆盖 ordinary integer/FP load 的 dispatch、reservation、
  bank launch、最终 PA disposition、response、formal WB、killed drain 与双 ROB retirement；
  bank-local MIQ 继续只承载 transport，SQ 保持唯一 physical byte ordering oracle
- ★ `ooo-memory-producer-lease` — **v8g 异步内存 ProducerId 租约合同**：
  exact owner token 间接携带不可变 PID、寄存 memory-live PID 位图阻断同名 ROB 候选、
  response 在 formal WB 前做 exact-open；当前 memory active-owner scoped implementation 已闭合，
  全核 no-live-reuse 仍 RED
- ★ `ooo-mmu-epoch-owner` — **R4-S2-Q1 data-MMU boundary/epoch 叶 owner**：
  held request、首拍 capture block、full-quiet sticky grant 与 grant-fire modulo-4 epoch；
  已进入 source catalog，尚未接入 live core/MMU barrier
- ★ `ooo-memory-typed-abi` — **R4-S1.0 typed post-translate ABI 规范真源**：
  CACHED/NC/IO 编码、PMA/PBMT 矩阵、fault/attr、owner token/MMU epoch 生命周期及
  single-owner/S2 RED 边界；S1.1 typed PMA/classifier 叶模块已实现，exact token/tuple 已在
  compatibility single-owner 路径贯通；typed epoch、完整 class routing 与双 owner 仍未贯通
- ★ `ooo-mem-axi-bridge-fsm` — 访存桥 FSM(probe/pretrans/nokill/store 解耦/单 outstanding)
- ★ `ooo-data-word-cache` — 数据侧 8B line D-cache 语义、debug/common checker 与 macro/OOC 前置合同
- ★ `ooo-sv39-tlb` — Sv39 TLB(64 项/上下文/superpage)
- ★ `pmp-checker` — PMP 检查器(16 项 TOR/NA4/NAPOT)
- ★ `ooo-pma-checker` — 当前 NpcTop 实例静态地址图检查器（完整 byte range、空壳/default fail closed）
- ★ `ooo-lsu-axi-lane-adapter` — LSU 逻辑 byte window 到标准 64-bit AXI lane/AxSIZE，非对齐逐 byte split
- `ooo-store-bresp-precise-terminal` — T4N plain-store probe/physical-write/B/ROB-release 三事件、
  cause7+tval-VA 与 T4M post-translate device 交叠合同
- `yosys-macro-boundary-contracts` — Yosys 四黑盒宏/OOC 边界合同（timing/area/语义缺口与任务清单）
- `ooo-memory-access`(wrapper)〔`ooo-pending-memory-sequencer` 已 B4 物理删除 → `history/`〕
- LSQ 现状：SQ(4)+probe/late-B precise physical write+store→load 前递已落地；shared LQ(16)
  已接入 ordinary integer/FP load 的 retire-resident 生命周期；MSHR 与更深的 cache-miss
  outstanding 仍未实现（见 current snapshot §2/§4；旧实施方案已归档
  `history/ooo-lsq-implementation-plan.md`）
- HW A/D 当前语义由 `ooo-fetch-axi-bridge` 与 `ooo-mem-axi-bridge-fsm` 承载；一次性实施
  计划 `history/ooo-sv39-hw-ad-update.md` 已归档。IFU partial-write flush-drain 已于
  2026-07-12 关闭；PTE write PMP 边界已由 2026-07-14 T4F 的独立 WRITE checker 关闭。

## 取指 / 前端 / 分支预测
- ★ `ooo-fetch-axi-bridge` — 取指桥(ITLB+硬件 PTW+硬件 A update+取指包 cache+PMP；
  IFU A-update flush-drain、page-fault byte provenance 与 PTE-write PMP 合同已关闭；
  其余精确 physical access/tval 边界仍按 active spec 跟踪)
- ★ `ooo-fetch-packet-cache` — 取指包 cache 语义、debug/common checker 与 macro/OOC 前置合同
- `ooo-fetch-packet-*`、`ooo-fetch-predecode-bundle`（T3V packet 所有权边界预译码）、
  `ooo-fetch-pc-outstanding-sequencer`、`ooo-fetch-request-mux`、
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
- ★ `ooo-pending-system-csr-producer-lease` — **v8k pending CSR ProducerId lease 合同**：
  pre-ROB capture 不伪造身份，真实 ROB dispatch 沿锁存 full PID，Q-only lease 并入 birth fence，
  commit 用 full PID+PC coherence 精确授权并封住 mismatch 的 head0 回退；feedback-free admission
  以精确 jump outcome 避免 orphan P 与 raw-ready 自锁；当前 v8k local scope 已验证闭合，
  全核 finite-generation no-live-reuse、architecture promotion 与 PPA 仍 RED/unqualified
- `ooo-control-plane`、`ooo-commit-output-mux`、`ooo-csr-*-mux`、`ooo-pending-system-sequencer`、
  `ooo-pending-trap-exit-sequencer`、`ooo-stop-pending-sequencer`(域 B 仅剩 system/trap 类)、
  `ooo-trap-exit-*`、`ooo-pending-dispatch-arbiter`、`ooo-pending-lane1-capture-gate`
- `ooo-fence-drain-ordering` — 普通 FENCE 的 pending-system 序列化、
  backend/SQ/MIQ/bridge 全 drain 与 exactly-once ISA retirement 合同
- 〔`ooo-synthetic-lane1-ret-sequencer`(+CommitGate) 已 B4 物理删除 → `history/`〕

## 装配 / 总线
- `ooo-core-top-glue`、`ooo-writeback`、`ooo-control-plane`、`ooo-memory-access`(子系统 wrapper)

## 说明
- 整体架构见 `../arch/ooo-core-architecture.md` 与
  `../arch/rtl-ground-truth-2026-07-11.md`(CURRENT snapshot)；流程/优先级见 `../arch/ROADMAP.md`。
- **归档区**:`history/`(spec 与一次性实施方案)、`../arch/history/`(arch 过程文档),
  各自 README 有逐份归档原因与现状参考。
