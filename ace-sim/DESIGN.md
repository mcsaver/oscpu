# ACE-Sim 设计地基

> **ACE = Activity-driven, Completion-event, Eval-driven**
> 活动驱动、完成事件驱动、eval 驱动的**周期级体系结构仿真器**。

本文件是整个系统的**北极星(north star)**。任何代码改动都不得违反第 1 节的核心不变量;
若确需修改不变量,先改本文件、说明理由,再改代码。

---

## 1. 核心不变量(不可违反)

来自设计讨论第 30 节,逐条落地为代码约束:

1. **Event 不直接修改架构状态**。到期事件只投递到目标模块 inbox,由目标在自己的
   phase 中处理。→ 见 `EventWheel` / `SimContext::deliver_due_events`。
2. **Completion ≠ Commit**。完成事件只表示"结果产生 / 依赖可唤醒",不改架构状态。
3. **所有架构状态只能在 Commit(Retire)边界改变**。V1 无 ROB,退休即 in-order 写回边界。
4. **所有时序状态必须 cur/next 分离**。eval 阶段只读 `cur`、只写 `next`;EdgeCommit
   阶段 `cur = next`。→ 见 `Reg<T>`。
5. **多周期操作必须同时建模三件事**:completion time、resource occupation、
   bandwidth/port 约束。→ 见 `FunctionalUnit`(latency / initiation_interval / width)。
6. **跨模块通信必须经过 port / queue / packet / event**,禁止 `a->b->c->access()` 深调用。
7. **backpressure 必须由 queue 容量 / ready-valid / 资源可用性表达**,不靠全局同步扫描。
8. **Branch squash 用惰性取消(O(1)),不逐个删 wheel 里的事件**。机制 = 每指令携带**全局唯一
   单调 dyn_id**;squash 使错误路径指令的 ROB 槽被置无效/被新指令复用(dyn_id 不同),其陈旧完成
   事件在 `on_wakeup` 被 `!valid || dyn_id≠payload0` 丢弃;更老正确路径指令的槽仍有效、dyn_id 匹配,
   照常应用。**注**:全局 fetch-epoch 无法区分"更老正确"与"更年轻错误"(同代),故不能用作判死标准
   ——V4 实测证伪了最初的 epoch 方案,改用 dyn_id 标签。
9. **系统 inactive 时必须能跳到 next event**(time skipping)。→ 见主循环 `advance_target`。
10. **Phase 顺序固定**,保证确定性、可重复、可 debug。

## 2. 抽象层次

```
Time      全局周期 (Cycle = uint64_t,V1 单时钟域,1 tick = 1 cycle)
State     Reg<T>{cur,next}         —— 时序状态
Event     未来到期的跨周期事件      —— 进 EventWheel
Activity  当前需要 eval 的组件集合  —— ActiveScheduler
Resource  等待期间的资源占用        —— FunctionalUnit 等
```

## 3. Phase 顺序(V1)

固定顺序,每个推进的周期依次执行;harness 在 EdgeCommit 后、Wakeup 前把到期事件投递到
各组件 inbox:

```
EdgeCommit    cur = next(仅对本周期写过 next 的组件)
 (harness deliver due events -> inbox, activate target for Wakeup)
Wakeup        处理 inbox:completion / response / operand 唤醒
Arbitrate     port / bus / FU / writeback 端口仲裁
Eval          活跃组件计算 next-state / schedule 未来事件
Transfer      ready-valid / packet 传输
Retire        commit / 精确异常 / 中断边界(架构状态在此改变)
EndCycle      stats / trace / 下周期激活
```

> Phase 顺序不是自然定律,而是**微架构定义**。同一模型只要顺序固定即可复现。

## 4. 唤醒策略

V1 采用**保守的 next-cycle wakeup**(讨论第 24 节策略 A):
completion event 在周期 N 到期 → 结果在 N 被写入 `next` / reg ready 表 → N+1 可见。
稳定后再引入 same-cycle bypass(策略 B)。

## 5. 时间跳跃规则(第 23 节)

每个周期结束后决定下一个 `cur_cycle`:

```
next_target = INVALID
if 有下周期激活(任一 phase 的 active set 非空): next_target = cur_cycle + 1
if wheel 有未来事件:                               next_target = min(next_target, wheel.next())
if next_target == INVALID: 仿真静止 -> 结束
else: cur_cycle = next_target      # 可能一步跳过成百上千个空周期
```

## 5.1 睡眠安全律(hard-won,勿违反)

活动驱动的正确性依赖一条**非平凡**不变量:

> 组件在某周期"不自激、进入睡眠"当且仅当:它当前每一个阻塞原因都有一个**已在 wheel 中的
> 未来事件**负责唤醒它。

- 数据冒险(RAW/WAW):由 producer 的 completion/response 事件兜底 —— 安全。
- 内存端口 backpressure:由该 load 的响应事件兜底 —— 安全。
- **纯 wall-clock 条件**(如 FU 的 initiation-interval 窗口,当 `II > latency` 时)**没有**
  天然的完成事件兜底。若组件因此睡眠,将永久睡死 / 仿真提前静止。此时组件**必须显式调度
  一个自唤醒事件**(`EventKind::CpuWake`,at `FunctionalUnit::next_free()`)。

> 该律曾被违反(V1 首版审查缺陷 #2/5/9):`on_eval` 误以为"任何停顿都有事件兜底"。
> 教训:任何新的停顿来源上线前,先回答"谁把我唤醒?",答不上来就得自己调度唤醒事件。

> **推论(V3 审查确认的 critical 死锁)**:"停顿有事件兜底"还不够 —— **兜底事件不能被
> 停顿者自己挡住**。若一个就绪列表按 FIFO 处理、遇到不可发射项就 `break` 整类,则一个
> 等待中的 younger 项会 head-of-line 堵住其后、恰好能产生"唤醒它"所需结果的 older 项,
> 形成 A→B→A 的环形等待(load→store→load),而这个环没有任何外部事件能打破 → 静默死锁 +
> 提前 halt。**规则**:凡"停顿原因取决于同列表其它项的进展"的就绪列表(典型=LOAD 内存消歧),
> 必须**跳过**不可发射项继续尝试其后项,绝不能 `break` 整类。仅当停顿原因对全列表一致
> (FU 结构冒险 by CpuWake、端口 backpressure by 响应事件)时,`break` 才安全。

> **推论 2(V4 审查确认的漏唤醒 backing 洞)**:一个停顿被"某未来事件"兜底还不够 —— **该事件
> 真正到期投递时必须能重新驱动被停顿的动作**。反例:LOAD 端口满的 backing 是"in-flight load 的
> 响应事件";但投机核里这些 load 可能被 squash,其**陈旧响应**在 dyn_id 惰性取消处被丢弃时,若不
> 重激活 Eval,就漏掉了"端口已随 memory pop 释放"这一状态变化 → 端口停顿的**存活** load 永远等不
> 到重试 → 静默 halt。**规则**:`on_wakeup` 对**任何**投递到 inbox 的事件(含被惰性丢弃的陈旧
> 事件)都必须重激活 Eval —— "有事件来 = 输入可能变了 = 重新评估",正是 RTL 模块"任一输入事件
> 到达即重算"的语义。

## 6. 版本路线(第 28 节)

- **V1 ✅**:CycleSimpleCPU(in-order,scoreboard)+ 多周期 FU + EventWheel +
  ActiveScheduler + cache 延迟模型;无 ROB。证明 7 个内核性质。
- **V2 ✅**:CycleOooCpu —— 寄存器重命名(RAT+free list+物理寄存器堆)+ issue queue
  (完成驱动唤醒:producer **完成**即写物理寄存器+唤醒依赖者,非退休)+ ROB 按序精确 commit。
  真正乱序:younger 独立指令越过 stalled older 指令发射/完成,但按程序序退休。
  head-to-head 同程序比 V1 顺序核更快;completion≠commit(不变量 #2/#3)彻底落地。
  暂无投机(分支=V4)故 RAT 无需 checkpoint/RRAT;暂无 store(=V3)。
- **V3 ✅**:LSQ —— 引入 **store**(内存从只读变可写)。store queue 兼作 store buffer:
  dispatch 分配、execute 拍算地址/数据、commit 标 committed、drain 按程序序落存。
  **store→load 前递**(命中最年轻的更老同址 store,免访存)+ **内存消歧**(任一更老 store
  地址未知则 load 必须等待,不得越序读内存)+ **HALT 前 store buffer fence**。
  暂为 word 粒度、地址/数据同拍产生;多级 cache 层级、STA/STD 拆分、byte-overlap 留后续。
  > 本阶段核心不变量:**"更老 store 地址未知 ⟹ load 等待"** 与 **"同址写序 = 程序序(按序 drain)"**。
  > 这正是 rv64 主核 LSQ 反复腐蚀的"队头=序安全"家族;在此干净模型里由 disambiguate_load +
  > in-order drain 保证,并有 memory-disambiguation 自检钉死(load 地址锁在 20 周期 DIV 后仍前递正确)。
- **V4 ✅**:投机执行 —— PC 驱动取指 + bimodal 分支预测(2-bit 饱和计数器)+ 误判 squash
  (flush 更年轻 ROB/IQ/SQ + RAT 快照回滚 + free-list 恢复 + 取指重定向)+ dyn_id 惰性取消。
  控制流参考模型对拍;循环 demo 学习预测器并从两向误判恢复;含分支的随机差分 2 万程序、
  ~2.3 万次 squash 全部 regs+mem 一致。
- **V5 ✅**:functional backend 与 timing engine 分层。`isa/FunctionalBackend` 可步进/可界定的
  纯功能执行("0 周期"),ref_model 委托它(功能模型 = difftest 金标准同一份代码)。**fast-forward**:
  功能快进无趣前缀到 ROI 入口,把架构状态(寄存器+内存+PC)种子进详细核(`start_pc`),只对 ROI
  做 cycle-accurate。三方(golden / full-detailed / hybrid)regs+mem 一致;典型:快进 602 条、
  ROI 详细仅 9 周期 vs 全详细 412 周期。JIT/DBT 是功能后端的性能优化(后续)。

## 7. V1 验收目标(必须由自检断言证明)

1. cur/next 状态正确
2. event wheel 正确(含 far-future 溢出桶)
3. active set 正确(只 eval 活跃组件)
4. ALU / MUL / DIV 多周期 completion 正确(latency/II/width)
5. frontend 在 FU 等待期间可继续推进
6. 队列满时 backpressure 正确
7. 系统 blocked 时可跳到 next event
