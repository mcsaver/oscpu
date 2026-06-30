# B2 · 多级分支投机 + 统一 redirect —— 拆除 branch/jump pending

> 2026-06-29。本规范定义 **B2**：把条件分支与 JALR 从「域 B 串行（pending + 全后端 drain）」迁回
> 「域 A 真乱序」，并把分散的取指重定向收敛为单一 control-flow arbiter。B2 是拆掉
> `OooPendingBranchSequencer`/`OooPendingJumpSequencer` 的前置，也是 **B-LSQ（投机 load 越过分支）**
> 与 **serialize-at-retire 清理** 的共同地基。定位见 `ooo-core-architecture.md` §8.3/§8.4。
>
> 本文件是 **spec 先行**产物：尚未动 RTL；记录方案评估、决策、规范字段与实施/验证计划。
> 决策依据：本日 3 方案设计 + 4 维评审 workflow，详见 `.github/task-runs/2026-06-29-rv64-ooo-core-architecture-constitution/`。

## 1. 现状（审计实测，带 file:line）

- **投机在生产里是关的**：`core/OooCoreTopGlue.v:554` `direct_branch_spec_start_w = 1'b0`——分支不走
  现有的单级 checkpoint，而是落进 pending + 全后端 drain（域 B）。
- **只支持 1 条在飞投机分支**：`OooRenameMap/OooFreeList/OooBusyTable/OooRob/OooIntIssueQueue` 各有**一份**
  `checkpoint_*_q`（单拍全数组拷贝），且现模型是「先把后端 drain 静默再快照、投机期冻结 commit」的弱模型
  （`OooBranchResolveRecoveryGate.v:66-73`、`OooCoreSliceControlGate.v:34-37`）。
- **无显式 mispredict 位**：`OooIntBackend.v:105-112,1816-1837` 只导出 `branch_resolve_valid/pc/next_pc/misaligned`，
  且**不导出分支的 rob_idx**；误预测靠前端比对实际 `next_pc` 与预测 PC **隐式**判定（脆弱）。全核 grep `mispredict` 无任何标识符。
- **重定向分散**：取指 PC 重定向有 10+ 源，由 `OooFetchRequestMux.v:45-79` 隐式优先级链择一；trap/flush 另在控制面汇合（见宪法 §7.3）。
- **已有可复用件**：ROB 每项已存 `arch_rd/rd_en/old_pdest/new_pdest`（`OooRob.v:93-96`）——正是回滚 rename 所需；
  ROB 有 `head/tail/count` + 环形指针；`OooIntBackend.v:859` 已有 `rob_idx_older_than()` age 比较原语；
  IQ 每项带 `rob_idx`；execute 级有 `flush_i` 入口（`OooIntBackend.v:997,1032`）。

## 2. 方案评估与决策

3 方案（均把分支迁回域 A，区别在**误预测恢复机制**），4 维评审打分（5 最好）：

| 维度 | A：branch-tag + N 份 RAT 快照 | B：ROB-walk 回滚 | C：K=2 RAT 快照 + walk 混合 |
| --- | :---: | :---: | :---: |
| 时序 / Fmax | 3 | **5** | 4 |
| 正确性 / 验证 | 4 | **5** | 3 |
| 性能 / 投机深度（恢复延迟）| **5** | 3 | 4 |
| 面积 / 集成 / 删 pending 干净度 | 2 | **5** | 4 |
| **合计** | 14 | **18** | 15 |

- **A** 恢复 O(1) 单拍（最利 `branch-resolve-loop` CPI），但重新引入 N 份 RAT 拷贝、按分支快照 `free_list.count_q`
  会**扇到 iter8 实测封顶链**（`free_list.count_q[4]→busy_table→issue_queue`，ROADMAP §7），验证踩坑面也大。
- **B** 不做任何 per-branch 快照：以分支 rob_idx 为界从 ROB tail 反向 walk，用 `old_pdest` 还原 RAT、回收
  `new_pdest`、回退 tail。恢复信息=ROB 单一真相源 → 无 checkpoint 陈旧/泄漏/tag 回收类 bug；可**删除约 6.5Kb 影子阵列**
  （ROB/IQ 全内容快照 + rename/free/busy 单影子）；对 Fmax 最友好（恢复代价是「拍数」不是组合深度）。
  唯一短板：误预测恢复多拍（ROB=16 → 最坏 ~8 拍、均 ~4 拍）且 walk 期冻结后端。
- **C** 混合：最老 K=2 条分支留 RAT 快照（1 拍恢复，恰好覆盖热循环回边分支）、更深者走 walk；面积同 B 为负，
  但同时继承 A、B 两族 corner case，验证踩坑面最大。

### 决策：B 为 Phase-1 基线；C 的「最老分支快照」作为 Phase-2 可选快路径

理由：
1. **正确性/可删干净度/Fmax 三项压倒**——B 是把 branch/jump 迁回域 A 最稳、最小、最干净的路径；它直接达成 B2 的**架构目标**（删 pending、真乱序）。
2. B 的弱点（多拍恢复）**仍远优于今天「每条分支 drain 整个后端」**（那是更多拍 + 每条都付）。故 B 单独已是巨大净胜。
3. A 的 O(1) 优势只在恢复延迟一项，且只对误预测密集的 `branch-resolve-loop` 显著。这部分**可在 B 跑通、测出恢复延迟确为 CPI 瓶颈后**，再用 C 的「仅最老分支一份 RAT 快照（K=1/2）」增量加上——**不必前置承担 C 的双族验证成本**。
4. ROB 仅 16 项、满 ROB 现实最多 ~3 条在飞分支（~5 指令/分支）；A/B/C 的「在飞分支数上限」差异在本核几乎不区分，胜负手就是恢复延迟与工程风险——支持「先 B、按需加快路径」。

> A 不被丢弃：若 Phase-1 实测恢复延迟主导 CPI 且 C 的快路径不足，A 的 per-branch 快照是 fallback。本规范保留其设计于评审记录。

### 2.x 验证负结论：休眠单 checkpoint 投机路径不可复活（2026-06-29 实测）

曾试一把高风险大刀——直接点火现核休眠的单级 checkpoint 投机（`OooCoreTopGlue.v` `direct_branch_spec_start_w` 1'b0→1'b1，
其余 spec tracker / checkpoint capture-restore / recovery gate 都已接线）。**功能 gate 大破**：
- riscv-tests **255 PASS / 16 FAIL**（FAIL 集中在 `sb/sd/sh/sw/ld_st/st_ld/ma_data`、`divu/divw/remuw/remw`、`clmul/clmulh/clmulr`、`ma_addr`、`dirty`）；
- AM cpu-tests **25 PASS / 32 FAIL**（分支密集程序如 if-else/recursion/bubble-sort/quick-sort/prime 全部**活锁撞满 max-cycles**，CPI 飙到 1e5+）。

**根因判定**：失败横跨 store / 多周期(div/clmul) / 分支恢复三类——该 weak 单 checkpoint 机器的 quiesce/capture
对"多周期或访存在飞指令"系统性损坏架构状态，且基本分支误预测恢复在纯 ALU+branch 程序上即活锁（恢复未正确收敛）。
这正是它当初被硬置 1'b0 关死的根因，印证审计"弱模型"判断。
**决策**：**不复活、不调试此废弃路径**（它是架构上被 ROB-walk 取代的机制，修它＝补完已弃 WIP，投资在将被替换的代码上）。
已精确回退到 1'b0（绿核），此结论防止未来重蹈。真 OoO 多分支投机走 §4 的 **ROB-walk** 正道。
证据：`eval/results/20260629-210219-b2-spec-enable/`。

## 3. 共享地基（**与方案无关，A/B/C 都需要；先做这部分**）

### 3.1 显式 mispredict + rob_idx（替换隐式 next_pc 比对）

`branch_event` 增加 `mispredict` 与 `rob_idx`，由后端分支单元产出（取代前端隐式判定）：

```
branch_event {
  valid
  rob_idx              // 该分支在 ROB 的位置（kill 边界）
  mispredict           // 显式：resolved_taken/target ≠ predicted
  redirect_pc          // 误预测时的校正 PC（taken→target / not-taken→fallthrough）
  misaligned           // target[1:0]!=0（异常，走 trap 而非 redirect）
}
```
- 条件分支：`CompareUnit` 已在 issue 算 taken（`OooIntBackend.v:539-560`），补 `resolved_taken/target` 与预测比对。
- JALR：后端 AGU 算 `rs1+imm`，与 BTB/RAS 预测比对。

> **实现发现（2026-06-29，读码确认）+ 决策**：今天 **mispredict 检测在前端**，不在后端——
> `OooIntBackend.v:545` `issue0_branch_next_pc_w = taken ? target : issue0_next_pc_w`，其中 `issue0_next_pc_w` 是
> **fallthrough（pc+len）而非预测**；预测路径由前端 `OooBranchResolveRecoveryGate` 用其跟踪的 `branch_spec_pred_pc` 比对解析 next_pc 得出（全核无 `mispredict` 标识符）。
> 故"后端产出 per-branch mispredict"需要把**预测 next_pc 作为新 uop 字段从前端 threaded 到后端**（多分支 B2 必需：每条投机分支各带自己的预测目标）。
> 这是一处真实数据通路改动（dispatch→IQ→issue 加一字段 + 前端供源），列入**整合切片**，不在本增量步做。
>
> **本步已落地（✅）**：`OooIntBackend` 导出 `branch_resolve_rob_idx_o`（= emit ? issue0_rob_idx_w : issue1_rob_idx_w，
> 与 `branch_resolve_pc/next_pc` 同源），并随 `branch_resolve_*` 家族 plumb 到 `OooCoreTopGlue.core_branch_resolve_rob_idx_w`
> （暂 driven-but-unused，待 arbiter 接入）。纯增量：模块 TB **113/113**、`lint`、`check-rtl-style` 全绿。`rob_idx` 是 `kill_younger_than` 的年龄基准，与 mispredict 来源决策无关，故先行。

### 3.2 单一 control-flow redirect arbiter（宪法 §5.5）

新增唯一仲裁器，**取代** `OooFetchRequestMux` 的隐式优先级链与各控制面汇合点：

```
redirect_request {
  valid
  pc                   // 目标取指 PC
  reason               // branch_miss | jalr_miss | trap | xret | sfence | fence_i | debug
  kill_younger_than    // 胜者 rob_idx；下游 squash age 比它大者
  flush_fetch
  flush_backend
}
```
仲裁规则（**已实现并验证**：`vsrc/control/OooRedirectArbiter.v` + `tb_ooo_redirect_arbiter.sv` 13 例 RED→GREEN，
模块全套 113/113 绿、`check-rtl-style` 绿；本切片只建模块+单测，尚未接核）：
- **主判据＝年龄**：同拍多源取 **age 最老**（`age = rob_idx − rob_head`，环形减法）者胜——更老的重定向会 squash 更年轻的源本身，故无需固定三档覆盖序。
- **同 age 平手按类**：`trap > branch > direct`。trap/xret 只在 commit(ROB head) 产生 → 恒为最老 → 年龄律**已天然**给它最高优先级；类平手仅发生在"同一条指令既误预测又异常"（misaligned 分支），此时 trap 胜。
- `reason` 三类只**描述典型 age 位置、非固定覆盖序**：`IMMEDIATE`=dispatch 直算 direct（最年轻）/ `DEFERRED`=后端 branch/JALR 误预测（中）/ `TRAP_COMMITTED`=commit 异常·xret（最老）。
- 模块是**纯组合 selector**：透传胜者 `{pc, kill_idx, reason, flush_fetch, flush_backend}`，不发明 flush 策略（policy 留各源）。
- 修正记录：本节初稿曾写"IMMEDIATE > DEFERRED > TRAP_COMMITTED 固定优先级"，实现时发现该序**不正确**（会让一条更年轻的 direct 覆盖更老的 trap/branch）；正解是年龄律，trap 因恒在 head 自然最高。宪法 §5.5 同步以此为准。

### 3.3 kill-younger 机制（B 的 walk 与 C 的快路径都用）

mispredict(rob_idx=R)：
- **ROB**：`tail ← R+1`，清 R 之后所有 `valid`（环形 age，复用 `rob_ptr_add`）。
- **IQ**：8 项各带 rob_idx，并行比较「比 R 年轻」清 `valid`（替代今天 IQ 全数组 checkpoint）。
- **execute**：在途 op 经 `flush_i` 冲掉（`OooIntBackend.v:997,1032`）。
- **free-list / RAT**：被 squash uop 的 `new_pdest` 回收、RAT 还原——**这是各方案的差异点**（见 §4）。

### 3.4 重新启用投机 + JAL/JALR 归宿 + 访存序边界

- 解封 `OooCoreTopGlue.v:554`（spec start），分支不再进 pending。
- **JAL**：目标 `pc+imm` decode 即知，走前端 direct（`OooFetchRequestMux.v:46/64`）作 `IMMEDIATE` 重定向；仍写链接寄存器（占 ROB/pdest），但不需 walk/tag。
- **JALR**：后端 AGU 解析，按分支同机制恢复；BTB/RAS 预测。
- **访存序耦合（重要边界）**：在 **B-LSQ 落地前**，更年轻的 store 仍走 `pending_mem` 串行（宪法 §8.3 mem 类未拆），故投机只能越过 ALU/load；跨 store 的投机深度被 mem 序压住。B2 规范的投机深度上限以此为准，**不在 B2 内解 mem 序**。

## 4. 恢复机制（决策部分）

### 4.1 Phase 1：纯 ROB-walk（基线，先 ship）

mispredict(rob_idx=R) 后，从 `tail` 反向 walk 到 R（不含），每拍处理 2 条（对齐双发射双写端口）：
- 读该 entry 的 `old_pdest/new_pdest/arch_rd/rd_en`（`OooRob.v:93-96`，新增任意索引读端口）。
- `rename_map[arch_rd] ← old_pdest`（还原投机映射）；`new_pdest` push 回 free-list；busy 无需恢复（alloc 必重置 not-ready，`OooBusyTable.v:111-117`）。
- walk 完成后清 walk-FSM，恢复取指。最坏 younger=15 → ⌈15/2⌉=8 拍；均 ~4 拍；**仅 mispredict 时付**。
- **可删除**：`OooRenameMap/FreeList/BusyTable` 的单影子 + `OooRob`/`OooIntIssueQueue` 全内容 checkpoint 阵列（~6.5Kb）。

### 4.2 Phase 2（可选，按实测）：最老分支 RAT 快照快路径（C 的精简版）

若 Phase-1 实测 `branch-resolve-loop` 恢复延迟仍是 CPI 瓶颈：给**最老的 1（或 2）条**在飞分支各留一份
192-bit RAT 快照（热循环回边分支通常即最老未解析分支）→ 命中则 1 拍恢复 RAT（free-list 仍 head 回滚），
未命中（更深嵌套，罕见）退化到 §4.1 walk。**只在 walk 基线跑通 + difftest 全绿后增量加**，避免前置双族 corner case。

### 4.3 关键决策点（实施前需定）

- free-list 回滚：walk 逐条 push（Phase-1，简单稳）vs head 指针回滚（需保证投机期 commit 不泄漏）。Phase-1 取逐条 push。
- 恢复是否打拍（同拍 vs 下一拍）：综合后按 Fmax 实测定。
- Phase-2 的 K：默认 K=1（最老一条），按实测决定是否升 2。

## 5. 拆除清单（B2 完成时删除/改写）

| 模块/信号 | 处置 |
| --- | --- |
| `OooPendingBranchSequencer.v` | **删**（分支迁回域 A） |
| `OooPendingJumpSequencer.v` | **删**（JAL→direct，JALR→后端解析） |
| `OooBranchSpecTracker.v` / `OooBranchResolveRecoveryGate.v` | **删/收编**（单 spec FSM + 隐式判定，被显式 mispredict + arbiter 取代） |
| `OooStopPendingSequencer` 的 branch/jump 臂 | **删**（`stop_pending` 不再因 branch/jump 置位） |
| `OooFetchRequestMux` 隐式优先级链 | **改**（3 条隐式分支重定向收敛为 arbiter 的 branch_miss 输入） |
| `OooRenameMap/FreeList/BusyTable/Rob/IntIssueQueue` 的 `checkpoint_*_q` | **删**（B 用 ROB-walk，不需快照） |

> grep 实测 `pending_branch`/`pending_jump`/`branch_spec` 各穿透约 30 个文件——这是一次大面积横切手术，必须 spec 先行 + difftest 全程护航 + 逐切片 RED→GREEN。

## 6. 验证计划（difftest + 定向 TB；spec 先行 → RED/GREEN）

1. **地基先行 TB**（三方案共用）：redirect arbiter「最老 rob_idx 胜 + trap>branch_miss」优先级 + `kill_younger_than` 语义（复用 `rob_idx_older_than`）。
2. **difftest**（NEMU lockstep，端到端兜底）：启用投机后跑 CoreMark + riscv-tests（rv64ui 分支密集段）+ ACT，逐指令比对架构态。
3. **kill 范围 TB**：扩 `tb_ooo_rob.sv` 验 tail 回退清 younger；IQ per-entry age squash。
4. **嵌套误预测 TB**：A 投机 → B 投机 → B 正确解析 → A 误预测，断言 walk 到 A 边界、B 及其后全 kill、free-list 无泄漏；再测同拍双 miss 取最老。
5. **JALR 误预测 TB**：`rs1+imm` 解析 vs BTB/RAS 不符触发 redirect；JAL 走 direct 不进 walk。
6. **free-list 回收 TB**：投机期发生 commit 后误预测恢复，断言无 pdest 泄漏、被 squash 的年轻 alloc 重新可分配。
7. **同拍 commit vs kill 竞争 TB**：head 提交与 younger kill 同拍的边界。
8. （Phase-2）最老分支快照命中/未命中 → 1 拍恢复 / 退化 walk 的对照 TB。

## 7. 实施顺序

进度图例：✅ 已落地+验证 / ⏳ 进行中 / ⬜ 未开始。

1. **地基**（§3）：
   - ✅ **单一 redirect arbiter + 优先级定向 TB**——`OooRedirectArbiter.v`（纯组合 age-律 selector）+ `tb_ooo_redirect_arbiter.sv`（13 例，RED→GREEN 负对照验过）；`define.v` 加 `REDIR_REASON_*`；模块全套 113/113 绿、`check-rtl-style` 绿。**未接核**（下步接线）。
   - ✅ **`branch_resolve_rob_idx_o` 导出 + plumb 到 `OooCoreTopGlue`**（纯增量，113/113 + lint + style 全绿，暂 unused）。
   - ✅ **ROB-walk 恢复 FSM（kill-younger 的 ROB 侧核心）**：`OooRob` 加 `kill_valid_i`/`kill_rob_idx_i` + 多周期反向 walk（2/拍），emit `walk{0,1}_{arch_rd,old_pdest,new_pdest,rd_en}` 供 rename 还原/free-list 回收，收尾回退 tail；`recover_active_o` 冻结 dispatch/commit。in-core `kill` 接 `1'b0`→**行为中性**（构造可证 + 113/113）。`tb_ooo_rob` 加定向 walk 测（奇/偶 younger 两条终止路径 last_one/last_two + 存活完好 + 无-younger 边界），**负对照证断言有效**（删 last_two 终止即 RED）。
   - ⬜ **显式 mispredict**：把预测 next_pc 作为新 uop 字段从前端 threaded 到后端（§3.1 发现），后端按分支算 mispredict——整合切片。
   - ✅ **rename-map walk-restore 端口**：`OooRenameMap` 加 `restore_valid/restore{0,1}_{en,arch,pdest}`，恢复时 `map[arch]<=old_pdest`，lane1(更老)同拍 WAW 源序后写胜=最老 squashed 写者留存。in-core 接 0=行为中性。`tb_ooo_rename_map` 加恢复测（基本/未触及/同拍 WAW 老者胜/en=0），负对照(换 lane 序)证有效。113/113+lint+style 绿。
   - ✅ **free-list 回收=复用现有 `free0/1` push 口**（无需新模块逻辑）：恢复期消费者把 `free{0,1}` 源 mux 到 walk 的 `new_pdest`（恢复期 alloc 已冻结，每拍最多 push 2，count 复原）；busy-table 用 clear-on-realloc（亦无需改）。→ **恢复数据通路(ROB emit + rename restore + free reclaim + busy)新-RTL 仅 ROB-walk+rename-restore 两件，均已建+验证**。
   - ✅ **IQ age-squash**（`OooIntIssueQueue`）：加 `kill_valid/kill_rob_idx/rob_head_idx/recover_active`，kill 拍清掉比 kill_rob_idx 更年轻(age 更大)的程序序后缀 entry、recover 期冻结发射。in-core 接 0=行为中性（gating 经 TB 验证 113/113）。
   - ✅ **Step A 恢复数据通路端到端接线**（`OooDispatchBackend`）：ROB.walk{0,1} → OooRenameMap.restore_*（map[arch]<=old_pdest）+ OooFreeList.free{0,1}（`recover ? walk_new_pdest : commit_old_pdest` mux）+ IQ.recover/kill；ROB.recover_active 串起冻结。**kill 源 `rob_kill_valid_w` 暂置 0 → recover 永不触发 → 全 mux 选常规路径 → 行为中性**（lint 0、113/113）。
   - ⬜ execute flush：`recover_active` 门 in-途 op writeback（Step B）。
   - ⬜ **kill 源**：mispredict（需 §3.1 的预测 next_pc threading）驱动 `kill_valid/kill_rob_idx` + free/rename restore mux 接 walk 输出。
   - ⬜ 把 arbiter 接进核 + 解封投机 `direct_branch_spec_start` + 删 pending branch/jump（**行为变更、difftest 护航的整合切片**）。
   - ⬜ 把 arbiter 接进核：替换 `OooFetchRequestMux` 隐式分支重定向链。
2. **启用投机 + ROB-walk 恢复**（§4.1）：解封 spec start，分支走域 A，walk 恢复；逐切片删 pending（§5），每步 difftest + 全 gate。
3. **删影子阵列**（§4.1 末）：确认 walk 正确后删 checkpoint_*_q。
4. **测量** `branch-resolve-loop` 恢复延迟 → 若主导 CPI，加 **Phase-2** 最老分支快照（§4.2）。
5. B2 落定后，统一 redirect arbiter 即可承接后续 **serialize-at-retire**（system/trap → ROB 队头 + arbiter 的 TRAP_COMMITTED）与 **B-LSQ**（投机 load 越过分支）。

## 8. 开放决策（待用户/实施时定）

- Phase-1 直接做到「删影子阵列」还是先「投机 + walk」与「旧 checkpoint 并存」一轮再删？（建议：并存一轮，difftest 全绿再删，降风险。）
- Phase-2 是否纳入 B2 范围，还是单列后续迭代？（建议：单列，按实测触发。）
- redirect arbiter 是否同时承接 trap/xret（serialize-at-retire 一并做），还是 B2 只接 branch_miss、trap 维持现状到后续清理？（建议：B2 先接 branch_miss + 预留 TRAP_COMMITTED 接口，trap 迁移随后续清理。）
