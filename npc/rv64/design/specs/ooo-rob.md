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
| dispatch0/1 | valid/ready/rob_idx + pc/inst/rd/old_pdest/new_pdest | 在 tail 分配 ROB 项,返回 idx |
| wb0/1 | valid/rob_idx/data/exception/cause/tval/fflags/pdest | 乱序写 ROB Q；两个端口同拍命中同一 live idx 属非法 owner collision |
| commit0/1 | valid/pc/inst/rd/old_pdest/new_pdest/data/exception/cause/tval + is_fp_rd/fflags | head 程序序退休输出(FP 目的与 fflags 随行) |
| commit_ready_i / commit1_block_i | | 上游提交准入 / 单独阻断 commit1 |
| flush_i | | 冲刷 |
| kill_valid/rob_idx → walk0/1 + recover_active | arch_rd/old_pdest/new_pdest/rd_en/is_fp | ROB-walk 误预测恢复:squash 严格更年轻项,walk 输出供 rename 还原+free-list 回收;walk 期(含 kill 当拍)冻结 dispatch/commit,in-flight wb 仍被吸收 |
| checkpoint_capture/restore | | mode=1 下恒 gate,影子阵列为死硅 |

## 3. 状态与时序
- 环形:`head_q`(提交端)、`tail_q`(分配端)、`count_q`;每项 `valid_q/done_q/exception_q/rd_en_q/...`。
- dispatch:`count+dispatch < ROB_ENTRIES` 时 ready;在 tail 写入 valid=1,done=0。
- writeback:`done_q[wb_rob_idx] <= 1` 并写 data/exception/cause/tval/fflags；本拍只改变
  ROB state D，不组合形成 commit valid/payload。
- commit:只读上一沿稳定的 `done_q/data_q/exception_q/...`。因此 completion-to-retire
  固定增加一拍；双 WB/双 commit 稳态吞吐仍为 2/cycle。commit1 可被
  `commit1_block_i` 单独挡，且 `head1.exception=1` 时必须结构性禁止 commit1；older
  normal head0 可单独退休，异常项下一拍成为 head0 后才宣告精确 trap。
  提交时输出架构 rd/data、释放 old_pdest、推进 head。
- 异常:只有 head0 exception 可在 commit0 上报并触发精确 trap；任何 exception 都不得从
  commit1 lane 退休。head1 exception 只阻断自身，不阻断 older normal head0。
- 误预测恢复(ROB-walk):kill_valid 锁存存活分支 idx,从 tail 反向 2 项/拍 squash 严格更年轻项
  并逐拍 emit walk0/1(arch_rd/old_pdest/new_pdest/rd_en/is_fp,FP 目的经 is_fp 分流给 FP 簇),
  recover_active 期间(含 kill 当拍)冻结 dispatch/commit;但 in-flight 写回仍被吸收——存活(更老)
  项的结果若在此窗口回写被丢弃,其 ROB 项永不 done、head 卡死(被 squash 项由其后的 valid/done
  清 0 覆盖,无副作用);checkpoint 影子阵列(capture/restore)在 mode=1 下恒 gate,为死硅。

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

## 5. 关键路径
Vivado OOC:OooRob 单独 6 逻辑级/logic ~1.4ns(浅,健康),非 Fmax 瓶颈。深度 16 项 commit-select 简单。
(对比:DispatchBackend 把 ROB/free-list/busy/IQ 合一才深,见 `ooo-rename-alloc.md`。)

## 6. 验证
- 模块 TB `tb_ooo_rob`;集成 riscv-tests 271(精确异常/委托/重定向)、AM 56(分支恢复/异常/退休序)。

## 7. 变更记录
- 2026-06-28：逆向文档化(2-wide in-order commit / 精确异常 / checkpoint)。
- 2026-07-14(T3W)：删除 WB-to-head done/payload bypass，retirement 全部 Q-only；增加
  双 WB 同 live ROB idx 的 owner collision 合同与 negative evidence。
- 2026-07-14(T4N reviewer)：修正 head1 exception 的双退休反例；异常 lane 结构性限定为
  commit0，允许 older normal 同拍单独退休。
