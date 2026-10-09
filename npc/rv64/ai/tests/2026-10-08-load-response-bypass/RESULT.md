# 完整架构优化实验：普通 load 响应空 raw 旁路

**最终裁决：保留此局部架构优化，默认启用 RESPONSE_BYPASS=1。** 本轮已完成网页 Pro 咨询、本地合同核查、真实 RTL 实现、定向与整核正确性验证、完整程序 A/B、同约束真实库综合及布局前 STA。保留依据是完整程序收益、很小的面积增量，以及本次映射点全局 setup 改善、负 hold 端点不变。**CQ 局部路径显著变长；两版在原 1 ns 约束下仍 FAIL，本轮不是时序闭合、可靠 Fmax、功耗或 PPA 签核。**

工作区 /home/lyg/PA/ysyx-workbench，分支 ai；基线 HEAD 为 ec653b952ca3938c893f14d9696bcb6b05b65f60。开始时 tracked 文件没有用户未提交修改，既有 ai/ 内容保留。基线/候选生产 RTL、构建、输入与工具记录分别保存；未提交或发布本次修改。

## 实际改变与所有权边界

生产修改在 [R64Lsu.v](../../../vsrc/lsu/R64Lsu.v)。成功、对齐、非 store/atomic/side-effect、class<2 的普通 RAM load，在对应 raw lane 的**寄存占用确实为空**时，作为原 raw 来源参与原六源轮转仲裁。只有 CQ 本拍实际捕获，才抑制该响应的 raw enqueue；没有赢得仲裁、CQ 无信用或不满足资格时照常进入 raw queue。

保留原 raw 容量、上游寄存信用/ready、物理响应接受和 LSQ 释放边沿、完整 tag 与 ROB reuse 保护、kill/flush/晚到 drain、CQ/WB/ROB 接受边界。错误、IO、atomic、非对齐和 store 副作用仍走原路径。不借被杀 head 的 out_valid=0 冒充 raw 为空，也不把 WB 请求提示当作 CQ 实际捕获。

[LSU 拓扑](../../../vsrc/lsu/TOPOLOGY.md)已同步更新。新增观测只在仿真宏 R64_LOAD_COMPLETION_PROFILE 下启用，默认关闭，不驱动生产信号；普通综合不带该观测。

## 完整程序 A/B

双方使用 baseline/images 下完全相同的固定 ELF/bin、同一完整 NEMU reference、SystemTop、Verilator --assert 和 R64_ASSERT。四次完整运行均自然退出0并 PASS，没有降低迭代数或关闭对拍。

| 完整负载 | 基线周期 | 候选周期 | 减少周期 | 周期减少 | CPI 基线→候选 |
| --- | ---: | ---: | ---: | ---: | ---: |
| CoreMark，10 iterations | 9,241,964 | 8,968,518 | 273,446 | **2.958743%** | 2.871491404→2.786520087 |
| Dhrystone，10000 runs | 14,568,135 | 14,267,505 | 300,630 | **2.063613%** | 3.419212237→3.348652911 |

测量的是固定完整负载的模拟周期；宿主耗时只记录实验成本，不作为 CPU 性能指标。固定频率下对应速度比约+3.049%/+2.107%；实际可实现频率需独立物理收敛，不能用本次负 WNS 直接反算 Fmax。

CoreMark 的全部 CRC 和迭代数相同，但候选多13条退休、2次write。性能变化使最终%03d打印参数从96变129，改变klib两遍格式化路径；在同一候选仿真器上，以等长输入096/129的独立小程序完整对拍，精确复现+13 commits/+2 writes。没有隐藏退休差异，也没有删去打印段挑选数字。Dhrystone两版退休均4,260,670，reads/writes一致。

- [完整基准总结、命令与证据](../../../results/ai-architecture-20261008/candidate/BENCHMARK-COMPARISON.md)
- [机器可读基准比较](../../../results/ai-architecture-20261008/candidate/benchmark-comparison.json)
- [printf差异复现](../../../results/ai-architecture-20261008/candidate/printf-diagnostic/README.md)

## 机制证据和正确性验证

| 定向负载 | 基线周期 | 候选周期 | 解释 |
| --- | ---: | ---: | --- |
| 串行load_chain，9223条退休 | 123,042 | 114,849 | 减少6.6587%；8194个合格响应的response→CQ由1拍变0拍，response→WB由3拍变2拍 |
| 同一load_chain，带背压 | 123,083 | 114,893 | 减少6.6540%，保持对拍和响应归属 |
| lsu_contention | 29,436 | 29,426 | 仅减少0.0340%，机会数量不等于完整负载收益 |
| lsu_contention，带背压 | 36,082 | 36,006 | 减少0.2106% |

候选完整CoreMark有549,089个合格响应，548,982个同拍入CQ；545,666次WB接受+3,423次取消=总数。Dhrystone有1,011,563个合格响应，1,011,552个同拍入CQ；1,011,558次WB接受+5次取消=总数。两项pending=0、tag_collision=0，17个延迟桶与原始行完整保留；取消数单独核算。

验证包括：

- 16项相关LSU/队列/Completion/Dcache/Memory模块用例全部通过。
- 10组SystemTop完整NEMU+断言回归：program、Sv39、sdtrig、lsu_contention、backend_network，各含普通/带背压模式。
- 10个响应旁路反例，参数0/1×普通/请求背压共4组全部通过：单/双响应、CQ全满、两lane只有一个CQ信用、旧head取消与新响应同拍、flush/kill排空、CQ持有跨LSQ复用与ROB generation、错误/IO/LR/非对齐排除、fault/forward与响应争仲裁等。参数0保留原寄存路径。
- 4个既有prepared/fast-response/metadata/early-store分支通过；5项负向合同检查通过。
- 生产RTL经完整Verilator构建，保持原工程告警规则、真正RTL断言及完整NEMU；最终补丁做反向apply检查及diff whitespace检查。

[定向结果及刺激局限](../../../results/ai-architecture-20261008/directed/RESULT.md)、[模块日志](../../../results/ai-architecture-20261008/related-tests/run.log)、[负向检查](../../../results/ai-architecture-20261008/related-tests/negative.log)、[整核回归](../../../results/ai-architecture-20261008/native-regression/results.json)、[机制A/B](../../../results/ai-architecture-20261008/mechanism-comparison.json)。这些验证支持本次受限改动，不等于formal全状态证明或完整系统release验证。

## 同约束物理取舍

两版均为完整R64SystemTop、icsprout55 TT/1.2V/25°C、1ns时钟、ABC600ps、fanout8；真实标准单元和ICG检查保留，没有SRAM/数值引擎占位黑盒，没有新增false path/multicycle或放松SDC。以下是布局前映射STA，无布局布线提取寄生。

| 指标 | 基线 | 候选 | 变化 |
| --- | ---: | ---: | --- |
| 单元面积，μm² | 3,141,304.599995 | 3,144,021.999995 | +2,717.4，约**+0.0865%** |
| 全局setup WNS，ns | −2.173909903 | −2.119304419 | 改善0.054605484 |
| 全局setup TNS，ns | −137,820.312500 | −137,753.000000 | 改善67.3125 |
| 全局hold WNS，ns | −0.036660694 | −0.036660694 | 不变 |
| 全局hold TNS，ns | −0.087889202 | −0.087889202 | 不变 |
| 原1ns检查结论 | **FAIL** | **FAIL** | 均未闭合 |

顺序单元面积完全不变。标准min报告覆盖全部负hold端点：每组最差10条中3条负、其余非负，两版这3个端点及slack相同，属于platform、platform fabric和LSU request_queue ICG；没有把“最差值一样”直接当作整个分布一样。

**局部代价不可省略。** 内部寄存器Q启动的CQ payload最差slack约−1.531424→−1.892151ns，恶化**0.360726ns**；CQ control恶化约0.144790ns，raw control恶化约0.281939ns。重要起点包含提交端trap控制寄存器，并非单纯load数据位。CQ ICG有约0.005770ns退化；raw payload改善，raw ICG不变。

包含输入起点后，候选CQ payload最差slack−2.111715555ns，与全局−2.119304419ns仅相差7.588864ps。这是当前映射报告的路径排名差，**不能当作布局布线后的安全余量**。后续收敛原LSU瓶颈时，CQ很可能成为下一处限制；不能把reg-only的−1.892与global相减，声称有227ps余量。

仍保留候选，因为完整程序收益成立，本次全局最差setup和TNS未恶化、hold端点不变、面积代价很小。局部路径利用更多余量是实际取舍，不能描述成“所有时序指标都改善”。[完整物理对比及六组路径](../../../results/ai-architecture-20261008/mapped-export-recovery/PHYSICAL-COMPARISON.md)包含raw/CQ payload/control/ICG的max/min、Q起点、端点集合、fanout及负hold对照。

### 资源故障及恢复的可比性

候选完成映射后，我为并行设置的6GiB地址上限使最终flatten失败。保留原返回码和日志；未把资源失败当作timing FAIL或架构失败。恢复从完整映射.netlist.v.sim开始，按原yosys.tcl后续命令执行，没有再改RTL或ABC。

原检查点重读改变私有/公有线名表示并增加内存；12GiB的两种恢复尝试失败后，20GiB虚拟上限下串行完成，全部失败记录保留。两版走相同恢复路径。基线143个模块加整体hierarchy共144块的cell/层次统计相同；恢复后的基线**最终面积、两项WNS和两项TNS与原标准结果五项精确一致**。统计一致不单独作为formal证明，实际物理复现是额外核查。

[恢复核查](../../../results/ai-architecture-20261008/mapped-export-recovery/RECOVERY-COMPARISON.md)、[实验定义及资源记录](../../../results/ai-architecture-20261008/EXPERIMENT.md)保留过程。工作流已更新：先依据实测峰值决定并行和内存预算，避免为并行把单任务cap设到已知需求以下。

## 网页Pro在本轮的实际作用

通过用户指定的Codex侧边栏原会话实际发送本轮合同与问题；页面可见Pro模式，完整回答显示思考16m22s。咨询与独立基线/验证准备并行，最终裁决前已取回并核查全文。

网页重点检查了CQ实际捕获与提示的区别、空raw必须用寄存占用、一个信用下的双响应、错误/副作用排除、ICG和局部路径可能抵消消拍收益。部分通用推断与此工程不符，已本地纠正：本LSU的flush取消全部owner；物理token是受生命周期保护的LSQ slot，并非外部携带完整ROB tag；不能据RTL直连时钟推断综合后没有ICG。

网页建议没有被当作实现或验收结果。完整程序A/B确认收益，局部STA也证实其提醒的跨级组合路径代价；本地据全套证据保留，已有足够证据后没有重复咨询。

- [实际发送请求](request.md)、[网页完整回答](response.txt)、[本地逐项核查](LOCAL_REVIEW.md)
- [咨询完成截图](consultation-complete.png)
- [同一网页会话](https://chatgpt.com/c/6ac6309d-96a4-83e8-bbce-538e0ec038ed)
- [候选及最终文档补丁](candidate.patch)、[文件SHA256与基线绑定](candidate-manifest.json)

## 下一轮优先项

1. 用本轮保留点作为新基线，继续以完整负载周期和真实head阻塞原因区分瓶颈，不用raw-empty机会数代替收益预测。
2. 优先检查CQ路径的trap/取消扇出、资格与仲裁组合锥，要求下一候选保留本轮延迟收益并降低路径代价。
3. 独立推进原1ns的setup/hold闭合；涉及实现频率的结论需真实物理收敛，不能用负WNS反算。
4. 按实测内存安排EDA，保留同版本代码、输入、工具和约束绑定，再决定下一项昂贵实验。

本轮到此结束，不自动扩大为第二项架构重构。
