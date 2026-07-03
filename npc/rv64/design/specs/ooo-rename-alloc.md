# 规范：rename/分配/唤醒子系统（FreeList + BusyTable + Dispatch alloc 链）

> 模块：`rename_allocate/OooFreeList.v`、`OooBusyTable.v`、`OooDispatchBackend.v`(装配)、
> `OooRenameMap.v`。本子系统是 OoO 后端 **#1 Fmax 限制者**(Vivado 实测最深组合链)。
> 模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证(含 iter7 时序优化)。

## 1. 目的与范围
每拍为最多 2 条 uop 分配物理寄存器(free list)、维护架构→物理映射(rename map)、
标记/查询操作数就绪(busy table,唤醒边界)，并把分配结果写入 ROB/IQ。容量由 `OOO_*` 宏定义
(PRF 64、free 32、ROB 16、IQ 8)。

## 2. FreeList（环形队列）
- `fifo_q[head..tail]` 存空闲 pdest;`alloc0=fifo[head]`、`alloc1=fifo[head+alloc0_fire]`。
- `alloc0_ready=count!=0`、`alloc1_ready=count>alloc0_fire`;释放下一拍可分配(避免与 commit 时序耦合)。
- checkpoint 整表快照影子阵列在 `OOO_ROB_WALK_MODE=1` 下 capture/restore 恒被 gate,为死硅
  (2026-07-03 RTL 重读确认);误预测恢复实际走 ROB-walk(恢复期 free 源切换为 squashed uop 的 new_pdest)。
- **不变量 FL-I1**：count = 当前空闲数;post_alloc/free 计算带 `<PHY_REG_COUNT` 防溢出。
- **iter7 时序**：`alloc1` 改为并行读 `fifo[head]`/`fifo[head+1]` + alloc0_fire 过浅 2:1 select
  (取代 alloc0_fire 喂 64:1 mux 索引)，行为等价、DispatchBackend 42→39 级。

## 3. BusyTable（唤醒边界 + 同拍旁路）
- `ready_q[preg]`:alloc 置 0(忙)、wakeup 置 1(就绪);**同拍同 preg 时 alloc 写胜**(alloc 晚于 wakeup 生效,
  同拍回收重用 pdest 不误判就绪)。
- 组合查询 `query_ready(preg)`:preg==0→1;命中本拍 alloc→0;命中本拍 wakeup→1;否则 `ready_q[preg]`。
  即把同拍 alloc/wakeup 旁路进查询，保证 IQ 同拍看到最新就绪态。4 个查询端口(2 uop × src1/src2);
  另有 1 个仅含 wakeup 前视的 raw 口,唯一实例中地址接常量 0(死口,FP store fs2 就绪实际由 FP 簇自建 busy 数组提供)。
- **不变量 BT-I1**：x0(preg0)恒就绪;**BT-I2**：同拍 alloc+wakeup 同 preg 时 alloc 优先(忙)。

## 4. #1 关键路径（Vivado OOC 实测）
`free_list/count_q → alloc0_ready/fire → free_list alloc1_preg(fifo mux) →
busy_table query(alloc1_pdest 旁路比较 + ready_q 64:1 mux) → issue_queue 分配/ctrl 写使能`。
iter7 后 **39 逻辑级 / logic ~7.95ns**(16 LUT6),仍是全核最深。
- 已做的安全降级：alloc1 并行读(iter7)。
- **残余深度在 IQ 分配/写逻辑**(哪个 slot 写新 uop + 与 oldest-select/compaction 交互)。
- **完整降低需流水化 dispatch**：把"分配→busy 查询→IQ 写"切成 2 拍(rename 拍 + dispatch 拍)。
  代价：dispatch 延迟 +1 拍(影响 CPI,需评估;back-to-back 依赖唤醒时序也要重对齐)→属**专注重构**,
  须 spec 先行 + eval 三 gate 守 CPI/正确性 + 重综合验证 WNS。记为下一时序大目标。

## 5. 验证
- 模块 TB:`tb_ooo_free_list`/`tb_ooo_busy_table`/`tb_ooo_rename_map`/`tb_ooo_dispatch_backend`。
- 集成:riscv-tests 271、AM 56(数据相关/WAW/分支恢复路径覆盖 rename/alloc/wakeup)。
- iter7 A/B:行为等价(CPI 1.2647 不变)、DispatchBackend 42→39 级。

## 6. 变更记录
- iter7(2026-06-28)：free list alloc1 并行读时序优化。
- 本规范(2026-06-28)：文档化子系统 + #1 关键路径分析 + 流水化方向。
