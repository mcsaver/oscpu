# R3 落地前源码核查

本文保留实现前核查时的事实；后续实现、测量与淘汰结论见[第三轮报告](../2026-10-08-round3-cq-value/RESULT.md)。

核查对象是 [网页完整回答](response.txt) 的 R3：`LOCAL_CANCEL_PUBLISH + CQ_VALUE_BYPASS`。
保留网页架构选择；以下是当前源码事实和普通实现适配，不是新架构替案。
本次未修改生产 RTL、测试或 SDC，未运行新 RTL 仿真、综合或 STA。

## 性能机制成立的条件

当前 Issue 选择只读 ready_q，wake 在时钟边沿更新 ready，没有当拍 wake 直通 issue 的捷径。
假设 response 在 E0 被 CQ 捕获，已有 hint 及时拿到 WB grant，消费者已初始化、其他源就绪且 RR 有信用：

| 事件 | 当前 B | R3 预期 |
|---|---|---|
| response/CQ 捕获 | E0 | E0 |
| WB payload/accepted/certificate 捕获、CQ pop | E1 | E1 |
| 消费者 ready 更新 | E2 常规 WB | E1 CQ early |
| 消费者 issue / RR ingress 接收 | E3 | E2 |
| RR 实际读值快照 | E4 | E3 |
| 正常 ROB done / PRF 写入 | E2 | E2 |

这是源码边沿推导，尚非本轮动态实测。CQ→WB→PRF没有必然的数据空窗：CQ pop与WB捕获同边沿，
随后原WB转发可供值，再下一边沿写PRF。新增CQ路径必须同样捕获实际data和hit，不能只保存lane编号。

证据：[Issue:188](../../../vsrc/backend/R64Issue.v#L188)、[Issue:428](../../../vsrc/backend/R64Issue.v#L428)、
[WB:153](../../../vsrc/backend/R64Writeback.v#L153)、[WB:172](../../../vsrc/backend/R64Writeback.v#L172)、
[ROB:394](../../../vsrc/backend/R64Rob.v#L394)、[RR:445](../../../vsrc/backend/R64RegRead.v#L445)。

## 必须带入实现的修正

1. **新增两路独立 ROB short-owner 查询。** 当前 WB 的两个 owner query 已经经过 grant 选择，
   不能用于 grant-independent 的 CQ early。已有四路 short-owner 全被 ALU early/bypass 使用。
   可按网页条件化方案扩为六路或另加两路，保持完整tag/preg校验及正常WB certificate边界。
   证据：[WB:130](../../../vsrc/backend/R64Writeback.v#L130)、[WB:146](../../../vsrc/backend/R64Writeback.v#L146)、
   [Backend:245](../../../vsrc/backend/R64Backend.v#L245)、[ROB:123](../../../vsrc/backend/R64Rob.v#L123)。
2. **DEFER_READY 与移位量也必须消费新旁路。** early需接入初始化的ready_query_complete和驻留wake；
   RR除了最终operand，还在原读边沿形成shift_amount，新CQ命中要覆盖read_bypass_b_w。
   当前RR原四源是masked-OR加同preg同值断言，不是网页伪码描述的显式优先级树；沿原语义扩展。
   证据：[Backend:354](../../../vsrc/backend/R64Backend.v#L354)、[RR:201](../../../vsrc/backend/R64RegRead.v#L201)、
   [RR:287](../../../vsrc/backend/R64RegRead.v#L287)、[RR:635](../../../vsrc/backend/R64RegRead.v#L635)。
3. **修正 canonical kill 方程。** 令F=full_flush，V=ROB valid，A=原partial publication资格，Y=plan_younger，
   当前为 `K=V & (F | (A & Y))`，令 `P=V & A & Y`。网页写的 `K=F|P` 对完整位图不成立；
   LSU实际使用的最终资格满足 `F|K = F|P`。保留原canonical K，分离partial A/C时保留valid、pending、plan_valid。
   PREPARED_CANCEL的等价断言应核对完整owner denial，不可删除检查；全清仍作用于已退出ROB但尚待drain的owner。
   证据：[ROB:246](../../../vsrc/backend/R64Rob.v#L246)、[ROB:545](../../../vsrc/backend/R64Rob.v#L545)、
   [RequestQueue:128](../../../vsrc/lsu/R64LsuRequestQueue.v#L128)。
4. **ticket和value_ok要在LSQ释放前保存。** birth已有pnew/rd_write/rd_fp，需经CoreTop→Memory→LoadStore透传。
   raw/空raw旁路响应接受边沿、full-forward terminal接受边沿均能读取原owner字段。
   raw152和forward77压缩payload不保留全部RAM class/排除条件，因此必须在这些边沿保存value_ok。
   early资格显式要求普通RAM class<2、对齐、非store/atomic/side-effect、无error和非零GPR目的；fault恒0。
   空raw ticket选择必须跟raw_occupied而不是受kill遮蔽的raw_valid。不得向响应ready增加同拍partial kill反馈。
   证据：[Backend:228](../../../vsrc/backend/R64Backend.v#L228)、[LSU:1346](../../../vsrc/lsu/R64Lsu.v#L1346)、
   [LSU:1382](../../../vsrc/lsu/R64Lsu.v#L1382)、[LSU:1505](../../../vsrc/lsu/R64Lsu.v#L1505)、
   [LSU:1601](../../../vsrc/lsu/R64Lsu.v#L1601)、[LSU:1754](../../../vsrc/lsu/R64Lsu.v#L1754)。
5. **269 bit不是整个实现的状态成本。** 按RR现有四源快照直接扩成六源，4个terminal+2个ingress各新增
   2×64 bit实际数据和3×2 bit命中，共804 bit（数据768、命中36）。与网页ticket/发布位269相加，
   条件化声明增量小计为1073 bit。仍不是最终综合FF数或面积；常量和未用字段可能裁剪，其他实现改动另计。
   FPR rank不因新增两个GPR来源而直接加宽。证据：[RR:104](../../../vsrc/backend/R64RegRead.v#L104)、
   [RR:453](../../../vsrc/backend/R64RegRead.v#L453)、[RR:461](../../../vsrc/backend/R64RegRead.v#L461)。

## 同拍发布公式核对

按 [Commit:133](../../../vsrc/control/R64Commit.v#L133) 的非阻塞赋值优先级，网页简化更新式与
下一拍 `event_valid && (!event_trap || event_prepared)` 一致。独立枚举7个状态/条件布尔量的128组，0反例；
reset建立不变量后可逐拍保持。保留原trap_prepare/effect_allow/stop_birth定义，不能写成上一拍flush的寄存。
owner-denial化简的16组布尔枚举也为0反例；这只是状态方程核对，不是新RTL形式验证或仿真通过。

## 实验仍需回答

当前未发现推翻R3选型的源码前提错误。仍需真实实现与定向测试证明：消费者确实提前；目的凭据和值不串owner；
WB长背压、两lane、skid晋升、kill+response/交接、DEFER_READY相邻birth、tag/preg复用、load→shift均正确。
随后同一完整R3的CoreMark/Dhrystone和原约束SystemTop STA才能裁决整核收益。
重点物理风险是新增short-owner→IQ、CQ→RR扇出/选择、publish D及广播，以及原effect/mem_issued尾段。
源码核查不能给这些风险出具PASS；本轮不把候选ID CTL-05/BE-10写入当前生产拓扑。
