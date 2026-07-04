# IssueQueue — 发射队列

**文件**:`src/core/issue/IssueQueue.hh` · **↔ npc**:`OooIntIssueQueue`

## 职责
持 IQ 条目池 + 每 FU 类就绪列表 + 物理寄存器等待表;负责唤醒、就绪登记、squash 重建。
选择/发射的**执行**部分(读寄存器 / 算结果 / 发事件)由 `CpuTop` 按类做,经 `ready_list/at/free_slot` 访问。

## 状态
- `iq_`:条目池(`Entry{valid,queued,dyn_id,fu,src0/1,s0r/s1r,dst,rob_idx,imm,cond}`),`iq_free_` 空闲栈。
- `ready_[5]`:每 FU 类(ALU/BRANCH=0,MUL=1,DIV=2,STORE=3,LOAD=4)一个就绪列表(FIFO=oldest 优先)。
- `waiting_`:物理寄存器 → 等待它的 IQ slot 列表。

## 接口
- `bool full()`;`void insert(dyn,fu,src0,src1,s0r,s1r,dst,rob,imm,cond)`(登记 + 按就绪进 ready/waiting)。
- `ready_list(cls)` / `at(slot)` / `free_slot(slot)`:供 `CpuTop` 选择/发射/回收。
- `void wakeup(phys)`:phys 就绪 → 推进依赖者,两源皆就绪则入就绪列表。
- `void squash(branch_dyn, pregs)`:回收更年轻(dyn>branch_dyn)条目 + 从存活条目按 `pregs` 就绪重建。

## 不变量 / 行为
- `queued` 位防重复入队;`wakeup` 的 `!valid` 守卫防陈旧 slot 引用。
- **重建的必要性**:squash 后 `iq_free_` 变化,`ready_/waiting_` 可能残留陈旧 slot;`rebuild()`
  清空后从存活条目重算就绪 → 消除陈旧引用(V4 审查确认一致)。
- 选择由 `CpuTop::select_issue` 做,但 **LOAD 类必须跳过不可发射项而非 break 整类**
  (否则 load→store→load 环 head-of-line 死锁 = V3 审查 critical 缺陷,睡眠安全律推论 1)。

## 测试
`tb_modules::test_issue_queue`:未就绪源进 waiting、wakeup 入就绪、free_slot 回收、squash 回收更年轻。
