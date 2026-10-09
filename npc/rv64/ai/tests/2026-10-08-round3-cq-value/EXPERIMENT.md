# R3：同拍取消发布与CQ确值旁路

用户要求继续直到完成本轮。按[网页完整方案](../2026-10-08-topology-handoff/response.txt)及
[已核对修正](../2026-10-08-topology-handoff/LOCAL-REVIEW.md)实施一个完整R3，不重新预选架构。

完整边界：Commit同拍publish、LSU全清/partial分离及等价断言、birth目的凭据贯穿LSQ/raw/fullforward/CQ、
两路独立ROB身份查询、IQ初始化/驻留wake、RR实际data/hit快照及shift_amount、CQ→WB→PRF连续性。
保持正常WB完成、真实mem_issued/effect/store B、取消与drain边沿。

当前工作树已有round1响应旁路及文档/测试改动。修改前108份vsrc和相关sim/testbench支持文件已保存到
`npc/rv64/build/ai-r3-20261008/baseline-vsrc`及`baseline-support`。回退只恢复本轮实际修改文件，保留新增证据。

两个实验开关位于CoreTop：CQ_VALUE_BYPASS、LOCAL_CANCEL_PUBLISH；默认R3两者开启。
定向消融可用 R64_R3_DISABLE_CQ_VALUE_BYPASS / R64_R3_DISABLE_LOCAL_CANCEL_PUBLISH 编译定义。
这两个开关只用于有边界的机制与等价比较，未独立完整验证的半方案不进入保留点。

可观察裁决：真实消费者提前、相关定向/整核DiffTest正确；完整CoreMark10和Dhrystone10000均不退步且至少一项
周期下降0.5%；同约束SystemTop setup WNS改善至少0.10ns、setup TNS与hold不恶化。该实验目标不替代原正式PPA规范；
仍未满足1ns必须报告FAIL。基线分别8968518/14267505 cycles、WNS −2.119304419ns。

预算为一个完整R3物理设计点，两个开关仅做短测消融。完整bench历史并行宿主约53分钟，综合STA约44分钟峰值8.8GiB，
仅在资源允许时并行，不重复同一确定性测试。实现错误按root cause修复；架构事实推翻则回传同一网页会话。
结果已测：两个完整程序周期下降3.46925%/2.31645%，全局WNS退化7.698ps，联合R3未达到上述时序保留要求。
已恢复B，当前生产拓扑未标成R3；完整收益、反证与可重放补丁见[RESULT.md](RESULT.md)。
