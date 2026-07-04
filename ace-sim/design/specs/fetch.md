# Fetch — PC 驱动取指

**文件**:`src/core/frontend/Fetch.hh` · **↔ npc**:`OooFetchPacketDecode` + `OooFetchPcOutstandingSequencer`

## 职责
按 PC 逐条从 program 取指,分支/跳转在取指拍向 `Bpu` 查方向、预译码目标,沿预测控制流前进;
产出带预测元数据的 `Item` 进取指队列。误判时由 `redirect()` 清队重定向。

## 状态
- `pc_`:架构 PC(program 下标),受预测 / redirect 驱动。
- `q_`:`BoundedQueue<Item>`(容量 = fetch_queue_cap),满即 backpressure。
- `stopped_`:取到 HALT 后置位,永久停指(直到 redirect 复位)。
- `fetched_`:观测计数。

## `Item`(取指队列条目)
`{inst, pc, pred_taken, pred_next_pc, target}` —— 指令 + 取指拍的控制流预测。

## 接口
- `bool step()`:取指一拍(≤ fetch_width 条),返回是否有进展。
- `can_pop() / front() / pop()`:供 dispatch 消费。
- `void redirect(pc)`:清空取指队列 + `stopped_=false` + 跳 PC(误判恢复)。

## 不变量 / 行为
- **HALT 持久闸门**:取到 HALT 即 `stopped_=true`,其后不再取指(V1 审查缺陷 #4 的对应保证)。
- 分支预测:BRANCH → `bpu_.predict(pc)`;JUMP → 恒 taken(目标已知,不误判);其它 → PC+1。
- 目标为**绝对 PC 下标**(imm)。跑出 program 尾即停(无 HALT 的畸形程序不 halt,与 ref_model 一致)。

## 测试
整核差分 fuzz(取指行为在五版 demo + 4 万 fuzz 中隐式覆盖:数字逐位不变)。
