# RV64 OoO — B2 ROB-walk 纯乱序分支/跳转投机（mode=1 bring-up）

**日期**: 2026-06-30  
**分支**: ai  
**目标**: 把 RV64 乱序核从「域B 串行 pending（branch/jump/mem/fp/system/trap）」推进到**纯乱序超标量**——
branch+jump 改为投机执行 + ROB-walk 误预测恢复（B2），由 `OOO_ROB_WALK_MODE` 总开关门控。

## 当前状态（checkpoint）

- **`OOO_ROB_WALK_MODE = 1'b0`（mode=0 基线，已验证 271/0 green）**——所有 mode=1 改动均 mode-gated，
  mode=0 逐位中性（build OK + riscv-tests 271/0 + 模块 TB 113/113 + check-rtl-style + lint 全绿）。
- mode=1 **未完成**：核能跑数百条指令（远超此前 livelock 14/43），但仍在 riscv-tests setup/loop 处失败。
  剩余唯一根因已精确定位（见下「未决」）。

## 已实现（4 片 + 共享地基，全部 mode-gated）

- **片1 pred_npc threading**：新增与 `next_pc` 平行的 `pred_npc`（预测后继 PC）字段，从 `OooFrontendBackendDispatchMux`
  → OooFrontend → glue → ExecuteBackend → AluCoreSlice → AluDecodeBackend → IntBackend → DispatchBackend →
  `OooIntIssueQueue`（落地 `pred_npc_q`/`checkpoint_pred_npc_q`/`pred_npc_next_r` 数组）穿过。
- **片3 de-pend branch+jump**：`OOO_ROB_WALK_MODE` 下 `OooStopPendingSequencer`(branch/jal/jump 臂)、
  `OooPendingDispatchArbiter`(lane0/lane1 branch+jump capture) 全部门控为 0；`OooControlPlane` 加 `rob_walk_mode_w`
  接两实例。前端加非返回 JALR dispatch 期投机续取：`OooJalrBtb` 加第二组合查询端口 `spec_lookup_*`，
  `OooFrontend` 算 `jalr_spec_pred_target_w`（ret-hint→RAS / BTB hit / fallthrough），经
  `direct_jump_spec_fire` 接 `OooFetchRequestMux`/`OooFetchPcOutstandingSequencer`/`OooFrontendActionGate`。
- **片2 后端 branch+JAL+JALR mispredict 解析**：`OooIntBackend` issue 级把控制流解析从 BRANCH 推广到
  BRANCH/JAL/JALR，统一算架构后继 PC（BRANCH taken?target:fallthrough / JAL pc+imm / JALR (rs1+imm)&~1），
  与 threaded `pred_npc` 比较得 `mispredict`，按年龄选 lane（issue0 优先），mode=0 代数化简逐位等价。
- **片4 kill源 + commit-freeze + redirect 整合**：`OooDispatchBackend` ROB-walk kill 触发从 `checkpoint_restore_i`
  改后端显式 `branch_mispredict_valid_i`（片2 产出）；`OooCoreSliceControlGate` 在 mode 下去掉
  commit-freeze / mem-block / **checkpoint_quiesce**（critique#1，否则 spec branch 永冻 commit 死锁）；
  redirect 复用既有 **branch_resolve_untracked** 数据通路（`OooBranchResolveRecoveryGate` 在 mode 下把 untracked-raw
  收紧为「仅后端 mispredict」——同时解决 critique#4 latch（untracked 块已把 next_fetch_pc 锁存到目标）+
  critique#5 churn）。mispredict 信号逐层 plumb 到前端 recovery gate。

## mode=1 调试发现并修复的真实 bug（按发现序）

1. **wb-during-recovery 丢写回**（`OooRob`）：写回→`done_q` 只在 normal else 分支处理，`recover_q`/`kill_has_younger`
   期被跳过 → recovery 窗口内更老(存活)指令的在飞写回被丢 → 其 ROB 项永不 done → head 卡死。
   **修**：在 recover_q / kill_has_younger 分支也吸收写回（放 squash 之前，被压制项由后续 valid/done<=0 覆盖）。
2. **recovering_w 与 IQ 不一致 → 僵尸 ROB 项**：IQ 按 `kill_valid_i` squash/gate，而 ROB 的 dispatch-freeze
   `recovering_w` 只在 `kill_has_younger` 时为 1。kill 当拍若无更年轻项，ROB 不冻结而 IQ 仍 squash → 新 dispatch
   进 ROB 但 IQ 项被 kill → 僵尸项永不 done。**修**：`recovering_w = recover_q || kill_valid_i`。
3. **dispatch 层不知 ROB 冻结 → rob_idx 复用（核心 bug）**：`OooDispatchBackend.dispatch0_ready_o` 只看
   `rob_slot0_ready_w=(rob_count!=full)`，**不含 ROB 的 recover_active/kill 冻结**。kill/recover 当拍 ROB 冻结 tail
   不前进，而本层仍 dispatch → 多条指令共用同一 ROB 槽（实测 390/394/398 都 rob=12）→ wakeup 按 pdest 找不到唯一
   producer → 卡死。**修**：`dispatch_freeze_w = rob_recover_active_w || kill_valid_q`（均寄存信号，不成跨层组合环），
   gate `dispatch0_ready_o`。
4. **pred_npc 海量伪误预测**：曾用寄存 `next_fetch_pc_q` 作 d1.pred，它是滞后一个 packet 的全局取指前沿
   （指向本 packet 起点而非后继）→ not-taken 分支也被判 mispredict（前沿≠fallthrough）→ 每条分支伪 redirect。
   **修方向**：pred_npc 必须 = 前端**实际取指的后继**。已实现 `count>=2 → 下一条 FIFO entry pc0`
   （`OooFetchPacketFifo` 加 `head1_pc0_o` peek）+ `count<2 → next_fetch_pc_q`。
5. **wrong-path 提交**：用「全 fallthrough」作 pred 时，前端 BHT 预测 taken 取了 target，而后端 pred=fallthrough 判
   mis=0 不 squash → wrong-path(fail handler) 提交 → trap@0x140。改用真实预测后继后此类消失（count>=2 路径）。

## 未决（唯一剩余根因 + 修复计划）

**症状**：mode=1 在 riscv-tests 的紧循环回边分支处仍失败（核跑到 commit 200+ 才错）。  
**根因**：`pred_npc` 在 **count==0 bypass**（FIFO 空 + 取指响应当拍 bypass 到 dispatch）时不准——此时 head 后继
尚未入队，寄存 `next_fetch_pc_q` 当拍尚未从「本 packet pc」更新到「后继」，pred 滞后指向本 packet 自身。
若该 bypass packet 是 predicted-taken 分支 → 与前端实际取指不一致 → wrong-path 提交 / 伪 redirect。  
**已试**：
- 用组合 `fetch_req_pc_o` 作 count<2 源 → **UNOPTFLAT 组合环**（含后端 branch_resolve redirect，与 backend
  mispredict 成环）。
- 用「前端-only 组合预测后继」(`frontend_head_succ`，镜像 `OooFetchRequestMux` 前端 redirect 分支去掉后端项)
  → **仍 UNOPTFLAT**：条件分支方向项 `branch_target_dispatch`/`branch_fallthrough_dispatch` 依赖后端 redirect。
- 用 `head_packet_next_pc`(fallthrough) 作 count<2 → bypass-taken 分支 wrong-path 提交（add 退化到 78 指令）。

**修复计划（下次）**：环本质 = pred_npc(dispatch-bypass) → mispredict → redirect → 前端分支 dispatch 决策 →
pred_npc。打破方式（择一）：
1. **寄存 redirect**：把 `branch_resolve_untracked` redirect 打一拍（前端多取 1 拍 wrong-path，由 FIFO clear
   兜底），使 `frontend_head_succ` 不再组合依赖当拍 mispredict → 可用前端-only 组合预测后继。
2. ~~**禁止分支 dispatch-bypass issue**~~ → **已做（破环成功，见下）**，但仍需正确的 count<2 前端预测后继。
3. **per-packet 预测后继随 FIFO/bypass threaded**：在取指/bypass 当拍把「该 packet 预测后继」寄存进 packet 元数据
   （FIFO 加字段 + bypass 加寄存），dispatch 时 pred_npc 取它——彻底 loop-free 且对所有 count 正确。**首选**。

## 续（同会话延伸）：IQ 结构破环 + 前端预测后继再战

- **IQ 结构破环 ✅（已落地，lint 无 UNOPTFLAT）**：① `OooIntIssueQueue` 在 mode 下禁止 branch/JAL/JALR
  `dispatch-bypass issue`（`dispatch0/1_ctrlflow_mispred_w` AND 进各 bypass_allowed 线 + `dispatch0_jal_issue1_bypass`/
  `dispatch1_branch_bypass`/`dispatch1_jal_bypass`）；② **关键结构招**：`issue0/1_pred_npc_o` 恒取寄存
  `pred_npc_q[idx]`（不再三目旁路 `dispatch_pred_npc_i`）——控制流恒经队列故 pred_npc 取寄存值正确，非控制流 bypass
  的 pred_npc 无消费者，于是 `pred_npc→mispredict→redirect→前端预测→pred_npc` 经 `pred_npc_q` 寄存**结构性断开**，
  Verilator 不再判环。**这是正确改进，保留**（mode-gated bypass 抑制；issue_pred_npc 取寄存值 mode=0 中性，pred_npc 死）。
- **破环后 count<2 源再试**（环已破，可用组合信号）：`fetch_req_pc_o`（前端完整下一取指含 BHT）→ 仍失败
  （fetch_req_pc 含**后端 redirect** 项，被更老分支的 redirect 污染→对当前 head pred 错）；`frontend_head_succ`
  （镜像前端 redirect 分支）→ 失败（**缺 BHT 方向预测**：非 prefetch 的条件分支方向预测在 fetch-request 内、不在
  `branch_target/fallthrough_dispatch`）。
- **决定性观察**：`next_fetch_pc_q`（滞后指向 head 自身 pc）反而**最稳**（add 到 232 vs fetch_req 78/fallthrough 78）——
  因为滞后使「每条分支都伪 mispredict、但 redirect 恒指向其架构后继 0x..b0」=功能正确(慢)；而「pred 匹配了错误的前端
  预测」(fallthrough/fetch_req)则 wrong-path 提交→trap@0x140。
- **现卡点（add 在 232/test_21 的 `bne tp,t0,0x3bc`）**：not-taken 分支提交后前端仍走了 wrong-path(0x3bc 循环续)→
  trap@0x140。kill_has_younger 恒 false（分支恒为 ROB 最年轻）→wrong-path 仅在 FIFO，理应被 redirect+FIFO clear 清除，
  但仍提交→**疑 redirect/FIFO-clear 当拍与 wrong-path dispatch 的 1 拍竞争，或前端 BHT 预测与 pred_npc 在该分支处仍不一致**。
- **下次最优解**：方案 3（per-packet 预测后继：取指/bypass 当拍把「前端实际下一取指 PC」寄存进 packet 元数据，
  dispatch 取它）——对所有 count 正确、loop-free、不依赖 next_fetch_pc 滞后兜底。**或** 方案 1（寄存 redirect 打一拍）
  配合 `frontend_head_succ + BHT 方向项(head0/1_branch_pred_taken→direct_branch_pred_pc)`。

**进展量化**：mode=1 从此前 livelock(AM 14/43) → 现跑 add 232 / addi 178 / or 214 / jalr 76 条指令且分支解析正确
（JAL/not-taken bne 实测 mis=0），证 4 片 + 5 bug 修复使乱序数据通路+ROB-walk 恢复+kill/commit 基本工作，
唯前端投机流↔pred_npc 一致性的 count<2/bypass 边界与具体分支 wrong-path 残留。

## 续 2（同会话再延伸：IQ 结构破环 + 前端预测后继重建 + trap@0x140 系统根因）

- **IQ 结构破环（已落地，保留）✅**：`OooIntIssueQueue` 在 mode 下禁止 branch/JAL/JALR `dispatch-bypass issue`
  （`dispatch0/1_ctrlflow_mispred_w` AND 进各 bypass_allowed），并把 `issue0/1_pred_npc_o` 改为**恒取寄存
  `pred_npc_q[idx]`**（不再三目旁路 `dispatch_pred_npc_i`）。这从结构上断开 `pred_npc→mispredict→redirect→前端
  预测后继→pred_npc` 的组合环，使 Verilator 不再判 UNOPTFLAT——之后即可对 count<2 用**组合**前端预测后继。
- **frontend_head_succ（精确前端预测后继，验证可 loop-free）**：逐字镜像 `OooFetchPcOutstandingSequencer` 的
  next_fetch_pc 计算 RHS（含 BHT 方向项 `direct_branch_spec_start ? direct_branch_pred_pc`），去掉后端项。实测
  bne@0x1ac 正确解析（`prednpc=0x68c, mis=1, redirect 0x1b0`，前端 BHT-taken 被正确捕获）。**但脆弱**：仍有边界
  case 与前端实际取指不一致 → add 退到 84（< next_fetch_pc 的 232）。
- **决定性定性：`next_fetch_pc_q`（滞后指向 head 自身）反而最鲁棒（232）**——滞后使「每条分支都伪 mispredict、
  但 redirect 恒指向其架构后继」=功能正确(慢)；任何「更精确但与前端不完全一致」的源（fallthrough/fetch_req_pc/
  frontend_head_succ）一旦匹配了错误预测，wrong-path 就提交→trap@0x140。禁 bypass 反而把滞后减小→更脆弱（78）。
- **232 卡点根因（FETCHDBG 逐拍实测）**：operand 与分支解析**全部正确**（tp=1 bne→taken→0x3bc mis=1，
  tp=2 bne→not-taken→0x3dc mis=0；s1/s2 值对）。但 tp=2 bne(not-taken)提交后，前端**未取 0x3dc 却取到 0x140**→
  instruction access fault trap@0x140。即**前端投机流在 redirect 后的某时序取到了错误/非法 PC**，wrong-path 未被
  redirect/squash 清除。本质=前端投机/flush/bypass/outstanding 时序与 ROB-walk 单拍 kill 模型的系统性不匹配
  （单拍 kill 管不到 redirect 后陆续到达的 outstanding 经 bypass 的 wrong-path；且 mode 下 untracked redirect 未触发
  完整的 `direct_frontend_flush`「暂停 dispatch」语义）。
- **系统结论（多会话级正解）**：① **per-packet 预测后继随 FIFO+bypass threaded**（取指/bypass 当拍把前端实际下一
  取指 PC 寄存进 packet 元数据，dispatch 取之）——对所有 count loop-free 正确；② **完整 flush-in-progress 状态**：
  mispredict redirect 触发等价 `direct_frontend_flush` 的「冻结 dispatch + 丢弃所有在途(FIFO/outstanding/bypass)
  wrong-path 直到正确路径首条到达」，使单拍 kill 只需处理 redirect 前已 dispatch 的部分。两者须一起设计。

**清理**：本会话所有 `ifdef ROB_WALK_DEBUG` 调试 $display 块已全部删除（8 块：OooRob×4/OooDispatchBackend×2/
OooIntBackend×1/OooIntIssueQueue×1，FETCHDBG 亦删）；define.v 移除 `ROB_WALK_DEBUG`；`OOO_ROB_WALK_MODE=0` 保绿。
续调时重置 `define ROB_WALK_DEBUG` 并按本报告各 $display 模板重建即可。

## 验证坑/经验

- **difftest 在 csrwi 0x744(e4) 处对 NEMU 已知 diverge**（mode=0 也 diverge 但 tohost PASS）；调 mode=1 必须
  `--no-diff`，按 tohost(HIT GOOD/BAD) 判，否则被 e4 红鲱鱼带偏。
- 单测试调试：`objcopy -O binary <elf> x.bin` + `./build/NpcSimTop --image=x.bin --tohost=<nm tohost> --max-cycles N
  --batch --no-progress --no-diff --itrace`。`--itrace` 出 `#N pc=.. inst=.. next=.. xN(reg)<=val` 提交流。
- 临时 RTL 调试：`define ROB_WALK_DEBUG`(define.v) 开 `OooRob`/`OooDispatchBackend`/`OooIntBackend` 内
  `ifdef ROB_WALK_DEBUG` 的 $display（ROBWALK/KILLOBS/ROBSTALL/IQSTALL/DISP0/DISP1/CTRLFLOW），现已关
  （define 移除即 inert）；这些块**待清理**（或保留供续调）。

## 文件改动（vsrc，全部 mode-gated；mode=0 已验 271/0）
control/OooCoreSliceControlGate.v, control/OooStopPendingSequencer.v, control/OooPendingDispatchArbiter.v,
control/OooControlPlane.v, rename_allocate/OooDispatchBackend.v, writeback/OooRob.v, scheduling/OooIntIssueQueue.v,
execute/OooIntBackend.v, execute/OooExecuteBackend.v, execute/OooAluCoreSlice.v, decode/OooAluDecodeBackend.v,
frontend/OooFrontend.v, frontend/OooFrontendBackendDispatchMux.v, frontend/OooFetchRequestMux.v,
frontend/OooFetchPcOutstandingSequencer.v, frontend/OooFrontendActionGate.v, frontend/OooBranchResolveRecoveryGate.v,
frontend/OooJalrBtb.v, frontend/OooFetchPacketFifo.v, core/OooCoreTopGlue.v, include/define.v
+ 12 个 testbench tie-off（新 input 端口接 0/常量）。
