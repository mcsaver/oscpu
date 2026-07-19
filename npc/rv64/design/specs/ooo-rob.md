# 规范：重排序缓冲 OooRob

> 模块：`vsrc/writeback/OooRob.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证；
> T3W 起 retirement valid/payload 全部只读 ROB Q，不存在 WB-to-head 旁路。

## 1. 目的与范围
ROB 是乱序执行与精确提交的边界：执行可乱序完成(writeback)，但对外 commit、异常上报、
旧物理寄存器释放必须按 head 程序序发生。容量 ROB_ENTRIES=16(`OOO_ROB_INDEX_W`=4)。
2-wide dispatch / 2-wide writeback / 2-wide in-order commit。误预测恢复=ROB-walk
(2 项/拍反向 walk squash 更年轻项);checkpoint 影子阵列在 `OOO_ROB_WALK_MODE=1` 下
capture/restore 恒被 gate,为死硅(2026-07-03 RTL 重读确认)。

## 2. 接口（要点）
| 组 | 信号 | 含义 |
| --- | --- | --- |
| dispatch0/1 | valid/ready/rob_idx/producer_id + pc/inst/rd/old_pdest/new_pdest | 在 tail 分配 ROB 项；`producer_id={next_generation,rob_idx}` 只在 fire 时被接受 |
| wb0/1 | valid/rob_idx/data/exception/cause/tval/fflags/pdest | 乱序写 ROB Q；两个端口同拍命中同一 live idx 属非法 owner collision |
| commit0/1 | valid/producer_id/pc/inst/rd/old_pdest/new_pdest/data/exception/cause/tval + is_fp_rd/fflags | head 程序序退休输出(FP 目的与 fflags 随行)；producer_id 读槽内已接受 generation |
| commit_ready_i / commit1_block_i | | 上游提交准入 / 单独阻断 commit1 |
| head0_context_permit_i / fencei_retire_permit_i | | v8a 预留的 commit0 末端准入；live `NpcCoreTop` 精确 tie-high，低电平只供后续 owner 激活 |
| head0_retire_candidate_valid_o | | 不依赖 commit-ready/permit 的 Q-only 队头可退休候选观察 |
| head0_identity_valid_o / head0_identity_o | | live head-present 与 8-bit context shadow identity；当前只零扩展 ROB index，和下述 ProducerId 是两个独立合同 |
| head0_producer_id_o | | live head 的 `{slot_generation_q[head],head}` allocation shadow；尚未接 active authorization |
| producer query0/1 | valid + producer_id → current_exact | v8f 冻结：供 integer issue early-wake 检查当前 live incarnation；纯 Q 查询，不进入 ready |
| producer query2/3 | valid + producer_id → completion_open_exact | v8f 冻结：供 EX formal completion 检查 `valid && !done && exact ID`；`rst/flush` fail closed |
| flush_i | | 冲刷 |
| kill_valid/rob_idx → walk0/1 + recover_active | producer_id/arch_rd/old_pdest/new_pdest/rd_en/is_fp | ROB-walk 误预测恢复:squash 严格更年轻项,walk 输出供 rename 还原+free-list 回收;walk 期(含 kill 当拍)冻结 dispatch/commit；仅 upstream 已授权的 boundary/older survivor WB 可被吸收 |
| checkpoint_capture/restore | | mode=1 下恒 gate,影子阵列为死硅 |

## 3. 状态与时序
- 环形:`head_q`(提交端)、`tail_q`(分配端)、`count_q`;每项 `valid_q/done_q/exception_q/rd_en_q/...`。
- v8e allocation source：每槽另有 `slot_generation_q[3:0]`，默认 ProducerId 为
  `{slot_generation,rob_idx}`（4+4 bit）。候选分配读取该槽 generation+1，且只有对应
  `dispatch_fire` 才写回；presented-valid 但 backpressured 不推进。commit/head/walk 只携带槽内
  已接受值，raw ROB index 仍单独负责环形地址和 age/order。
- 普通 `flush_i`、commit 与 recovery 均保留 generation；硬复位把每槽置全 1，使首个候选为 0。
  后者只在 ROB、所有 ProducerId holder 与副作用端属于同一复位排空域时成立，不能推广为局部
  reset 可安全重名。
- v8f（合同已冻结、RTL 落地中）只增加无状态 exact query：PID 低位选择 slot，完整比较
  `{slot_generation_q[idx],idx}`；completion query 还要求 `!done_q[idx]`。query 不读取 WB 或
  ready，不能替代后续 global lease/no-live-reuse。
- dispatch:`count+dispatch < ROB_ENTRIES` 且非 reset/flush/recovery 时 ready；在 tail 写入
  valid=1,done=0。reset/flush 拍 parent 与 leaf ready 都 fail-closed，避免 valid&&ready 已宣告接受、
  但高优先级清空分支实际丢弃 entry/generation。
- writeback:`done_q[wb_rob_idx] <= 1` 并写 data/exception/cause/tval/fflags；本拍只改变
  ROB state D，不组合形成 commit valid/payload。
- commit:只读上一沿稳定的 `done_q/data_q/exception_q/...`。因此 completion-to-retire
  固定增加一拍；双 WB/双 commit 稳态吞吐仍为 2/cycle。commit1 可被
  `commit1_block_i` 单独挡，且 `head1.exception=1` 时必须结构性禁止 commit1；older
  normal head0 可单独退休，异常项下一拍成为 head0 后才宣告精确 trap。
  提交时输出架构 rd/data、释放 old_pdest、推进 head。
- 异常:只有 head0 exception 可在 commit0 上报并触发精确 trap；任何 exception 都不得从
  commit1 lane 退休。head1 exception 只阻断自身，不阻断 older normal head0。
- v8a shadow: `head0_retire_candidate_valid_o = !recovering && count!=0 && valid[head] && done[head]`；
  `head0_identity_valid_o = count!=0 && valid[head]`，identity 只零扩展 `head_q`。旧 commit0 条件先
  收口为 `head0_base_ready_w`，再与两个 permit 相与；live top 传入 1/1，故行为逐位等价。
  lane1 CSR/SFENCE.VMA/xRET/FENCE.I 只形成 observation shadow，禁止作为 commit1 条件。
- 误预测恢复(ROB-walk):kill_valid 锁存存活分支 idx,从 tail 反向 2 项/拍 squash 严格更年轻项
  并逐拍 emit walk0/1(arch_rd/old_pdest/new_pdest/rd_en/is_fp,FP 目的经 is_fp 分流给 FP 簇),
  recover_active 期间(含 kill 当拍)冻结 dispatch/commit;但 authorized in-flight survivor 写回仍被吸收——存活(更老)
  项的结果若在此窗口回写被丢弃,其 ROB 项永不 done、head 卡死(被 squash 项由其后的 valid/done
  清 0 覆盖,无 ROB 局部持久副作用)。producer 侧必须在进入 ROB 前切掉 strictly-younger
  completion，因为 PRF/Busy/IQ/public pulse 不可由 ROB walk 原子撤回；ROB 的 idx+valid 接纳
  本身仍不是 generation-safe full identity。v8e 虽已产生并在 ROB head/commit/walk 公开
  ProducerId shadow，但 WB/PRF/Busy/IQ 和上游执行 holder 尚未携带、比对它，因此 active
  authorization 仍为 RED。checkpoint 影子阵列(capture/restore)在 mode=1
  下恒 gate,为死硅。

## 4. 不变量
- **ROB-I1 程序序提交**：commit 只从 head 起按序;commit1 必为 head 的下一项且不早于 commit0。
- **ROB-I2 精确异常**：异常只在 commit 边界对外可见;异常项之后的项不得提交其架构副作用。
- **ROB-I3 旧 pdest 释放**：仅在该写 rd 的 uop 提交时释放其 old_pdest(回 free list)。
- **ROB-I4 容量**：dispatch ready 严格按 `count+本拍dispatch ≤ ROB_ENTRIES`,不溢出覆盖未提交项。
- **ROB-I5 Q-only retirement**：commit valid 与 data/exception/cause/tval/fflags 不得旁路
  任一 WB input；WB 拍 commit 必须为 0，下一拍才可观察 registered completion。
- **ROB-I6 单一完成 owner**：`wb0_valid && wb1_valid && wb0_idx==wb1_idx && valid_q[idx]`
  非法并 fail closed；禁止用源代码顺序隐式定义 lane1-wins。
- **ROB-I7 exception-lane0-only**：`commit1_fire -> !head0.exception && !head1.exception`；
  `head0 normal && head1 done+exception` 时本拍最多 commit0，下一拍异常项才可成为 commit0。
- **ROB-I8 v8a neutral shadow**：candidate 蕴含 identity-valid/done/非 recovery；identity-valid 不读
  done/commit-ready；live top 两 permit 恒 1；lane1 shadow 不进入 commit1。
- **ROB-I9 v8e allocation source**：`dispatch_fire(slot) -> accepted_pid =
  {slot_generation+1,slot}`，且 generation 只因该 accepted allocation 改变；双 lane、head、commit、
  walk 的 producer_id 必须与同一槽 incarnation 一致。raw index 不被 full PID 替代用于 age/order。
- **ROB-I10 finite-width non-proof**：任意有限 `PRODUCER_GEN_W` 都会回绕。未来启用 active
  identity 前必须满足 `allocation_fire(candidate) -> candidate ∉ global_still_live_reference_set`，
  并在 ROB/PRF/Busy/IQ/public side effect 前做 exact-ID authorization；当前两项均未实现，保持 RED。

## 5. 关键路径
历史 Vivado OOC:OooRob 单独 6 逻辑级/logic ~1.4ns(浅,健康),非 Fmax 瓶颈。深度 16 项 commit-select 简单。
v8e 新增的 per-slot generation 名义状态为 16x4=64 bit，另有候选加一与载体；尚未生成新的
综合/STA/power 证据，因此不得把历史数字当成 v8e PPA 结果，也不得宣称 PPA 改善或中性。
(对比:DispatchBackend 把 ROB/free-list/busy/IQ 合一才深,见 `ooo-rename-alloc.md`。)

## 6. 验证
- 模块 TB `tb_ooo_rob`;集成 riscv-tests 271(精确异常/委托/重定向)、AM 56(分支恢复/异常/退休序)。
- v8e 专项 runner：release/assert leaf+dispatch source test PASS；13/13 compile-success semantic mutations被测试
  检出；`PRODUCER_GEN_W=1` 显示 full identity 回绕且 allocation 仍 ready，记录为 expected RED。

## 7. 变更记录
- 2026-06-28：逆向文档化(2-wide in-order commit / 精确异常 / checkpoint)。
- 2026-07-14(T3W)：删除 WB-to-head done/payload bypass，retirement 全部 Q-only；增加
  双 WB 同 live ROB idx 的 owner collision 合同与 negative evidence。
- 2026-07-14(T4N reviewer)：修正 head1 exception 的双退休反例；异常 lane 结构性限定为
  commit0，允许 older normal 同拍单独退休。
- 2026-07-19(S2-Q2-v8a)：冻结行为中性的 precommit/identity observation、permit 预埋和 lane1
  context-boundary shadow；full identity、payload、FENCE.I/Q1/epoch 事务继续延期。
- 2026-07-19（v8d）：澄清 recovery 窗口只吸收 upstream-authorized survivor WB；
  strictly-younger EX completion 必须在 ROB 前截断，且本条不提升 idx-only WB authorization。
- 2026-07-19（v8e P1）：加入 4+4 bit ProducerId allocation shadow、per-slot generation 以及
  dispatch/head/commit/walk 载体；普通 flush 保留、accepted allocation 才推进。有限位宽回绕、
  global no-live-reuse、全 holder 传播与 exact writeback authorization 明确保留 RED。
