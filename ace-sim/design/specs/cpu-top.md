# CpuTop — 顶层核(实例化 + 流控编排)

**文件**:`src/core/top/CpuTop.{hh,cc}` · **↔ npc**:`OooCoreTopGlue` / `NpcCoreTop`

## 职责
类 RTL 顶层:**实例化 11 个模块 + 编排它们**。是内核 `Component`(参与活动调度);构造函数读如
Verilog top 的实例化列表,phase 方法做连线 + 流控(= npc "存储/流控决策留在 glue"的对应物)。

## 实例化(构造函数,读如 top instantiation)
`pregs_ · rename_ · freelist_ · bpu_ · fetch_ · rob_ · iq_ · sq_ · alu_ · muldiv_ · brres_`。
自身**不持有任何状态队列**;仅剩 `next_id_`、`structural_wake_`、观测计数。

## phase 编排(= 连线 + 流控)
- **Eval** `on_eval`:`select_issue`(乱序发射,读 IQ 就绪列表 → 读 PhysRegFile → Alu/MulDiv 或
  StoreQueue.execute 或 load 消歧/访存)→ `rename_dispatch`(Fetch→RenameMap/FreeList/Rob/IQ/SQ)→
  `fetch_.step()`。back-to-front,同周期复用释放资源。
- **Wakeup** `on_wakeup`:处理完成事件 → 写 PhysRegFile + `IssueQueue::wakeup`;分支 → `resolve_branch`。
- **Retire** `on_retire`:`Rob::head` 按序提交 → FreeList 归还 old_phys / StoreQueue.commit;drain store buffer。

## 关键不变量(睡眠安全律,DESIGN.md §5.1)
- 结构冒险(FU II)→ 记 `next_free` 调度 `CpuWake` 兜底(推论前身)。
- LOAD 就绪列表**跳过**不可发射项而非 break(HOL 死锁,推论 1)。
- `on_wakeup` 对**任何**投递事件(含被 dyn_id 惰性丢弃的陈旧事件)都重激活 Eval(漏唤醒 backing,推论 2)。
- HALT:Fetch 持久闸门 + Retire 前 store buffer fence + `ctx.halt`。

## 误判恢复 `squash_after`
`Rob.squash`(回收+归还 phys)→ `RenameMap.restore`(RAT 回滚)→ `IssueQueue.squash` → `StoreQueue.squash`
→ `Fetch.redirect` → 重激活 Eval。惰性取消靠 dyn_id 守卫,不删 wheel 事件(O(1))。

## 测试
五版 demo(V1-V4)+ 差分 fuzz(2 万 branchy + 2 万 port-stress):regs+mem 全程与 `ref_model` 一致。
