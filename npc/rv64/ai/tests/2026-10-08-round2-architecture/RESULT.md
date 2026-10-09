# 第二轮：网页 Pro 设计、Codex 实现的完成路径重构

**结论：淘汰当前完整候选，已恢复本轮前实现。** 网页Pro独立提出方案，经本地实现、完整验证和实测反证回访后作出不保留裁决。两个完整基准均正确且周期不变，但全局setup WNS和CQ输出路径退化；局部输入改善不足以支持替换主代码。上一轮保留的load response bypass及本轮前已有修改保持。

## 架构方案从哪里来

使用用户授权新建的[网页会话：架构优化方案推导](https://chatgpt.com/c/6ac732fa-befc-83e8-a497-7bf8b3c72ff0)。页面核实 GPT-6、Pro 第5/5档。向新会话发送当前硬件、完整负载计数、真实STA、生命周期约束及未知项，未把本地预选方案作为输入结论。

Pro比较了三个方向：确定load值提前供消费者使用、store地址/数据部分发射、完成搬运与取消资格解耦。它选择第三项，理由是现有映射网表已经显示取消控制进入宽完成数据路径，而前两项的收益还缺依赖链证据。本轮因此是以维持周期数为约束的物理结构优化，不预期重复上一轮的CPI收益。

- [实际发送的独立事实包](request.md)
- [Pro第一次完整设计](response.txt)
- [本地核查及接口反例](LOCAL_REVIEW.md)
- [实际发送的反例反馈](clarification-request.md)
- [Pro接受反例后的修订合同](revised-contract.txt)

初版候选公式使用bus_fire，但真实ready包含当前flush，因此取消仍间接进入宽数据选择。本地返回了固定状态下切换flush的具体反例；Pro随后将候选改为真实response VALID加取消前状态，而最终capture仍要求原raw_fire。实际实现采用修订合同，没有修改ready或延迟kill。

## 联合实现

实验候选修改仅两处，以下链接指向归档实现；当前主工作树已恢复本轮前版本：

- [R64Lsu.v](candidate-src/npc/rv64/vsrc/lsu/R64Lsu.v)：六个完成来源先按取消前候选选择和路由完整数据，再按真实握手、当前存活及信用建立完成owner；允许实际capture为10，RR只按真实捕获推进。
- [R64LsuCompletion.v](candidate-src/npc/rv64/vsrc/lsu/R64LsuCompletion.v)：每lane两个固定物理槽，总容量仍四条；出队/取消修改有效位和head，不搬运宽payload。只有旧状态已经空闲的槽允许预写，同一边沿真实capture才建立owner；reset关闭预写。

正常完成路径没有增加流水级，外部响应、LSQ/token生命周期、晚响应drain、store副作用和WB共同资格保持原合同。无owner的预写内容没有完成或reuse权限。取消候选可能占用当拍仲裁位置，以及固定槽输出mux的代价，都由实测裁决。

[本轮生产差异](production-candidate.patch)和[本轮测试/观察差异](support-candidate.patch)均相对本轮开始时的保留点，避免混入上一轮已有修改。工作区有用户及前轮未提交内容，未执行提交或整树回退。

## 已完成的正确性与机制验证

| 证据 | 覆盖与结果 |
| --- | --- |
| system-lint | 保持原规则及R64_ASSERT，通过；首次编译发现的旧event_two_w断言引用已改为稀疏capture守恒断言 |
| CQ直接验证 | 原完成/完整payload/WB request测试通过；30,022拍独立FIFO scoreboard，21,022捕获=19,493写回+1,529取消；含3,211次sparse10 |
| CQ非干扰及对照 | 相同Q态双实例改变取消和pop，路由/预写保持；reset无预写复活；冻结旧CQ无取消流逐拍对比6,003拍通过 |
| LSU仲裁 | 13,122组独立candidate/live/RR/credit oracle通过；六来源各25次服务，最长等待3拍；真实RR的00保持、10及dead-first/one-credit均覆盖 |
| 真实响应矩阵 | RESPONSE_BYPASS=0/1 × 普通/背压全部通过；实际响应同Q态kill/flush反例、双响应中取消rank0后的sparse10通过，未强制DUT内部状态 |
| 相关模块 | 14项相关模块通过；2项非法响应/非法store取消的负向测试按预期fatal |
| 整核短测 | program、sv39、sdtrig、lsu_contention、backend_network、load_chain各普通/背压，共12项完整NEMU与断言验证通过 |
| 正常load延迟 | load_chain中8,194个合资格load均保持response→CQ 0拍、response→WB 2拍；普通114,849周期、背压114,893周期，与基线完全一致 |

证据目录：[CQ](../../../results/ai-cq-timing-20261008/cq-modules/RESULT.txt)、[仲裁](../../../results/ai-cq-timing-20261008/lsu-arbitration-tests/results.json)、[相关模块](../../../results/ai-cq-timing-20261008/related-tests/result.json)、[整核短测](../../../results/ai-cq-timing-20261008/candidate/short-tests.json)、[load机制对照](../../../results/ai-cq-timing-20261008/candidate/mechanism-comparison.json)。

## 完整性能比较

基线为上一轮保留的response-bypass实现，候选仿真和综合均使用本轮同一冻结RTL。固定同一CoreMark 10次/Dhrystone 10000次镜像、完整NEMU、R64_ASSERT、threads=1。新增计数器只观察，不驱动RTL。

| 负载 | 基线周期 | 候选周期 | 基线/候选退休数 | 基线/候选CPI |
| --- | ---: | ---: | ---: | ---: |
| CoreMark 10 | 8,968,518 | 8,968,518 | 3,218,537 | 2.786520087 |
| Dhrystone 10000 | 14,267,505 | 14,267,505 | 4,260,670 | 3.348652911 |

两项均自然结束、完整DiffTest与断言通过；全部PASS计数、CPI_PROFILE、共有LOAD_PROFILE、17个延迟桶和程序输出完全一致。CoreMark五项CRC一致：seedcrc=e9f5、list=e714、matrix=1fd7、state=8e3a、final=fcaf。退休数、reads、writes差值全0，本轮不需要借用上一轮的printf差异解释。

新观察的取消candidate rank分别为599/10000次；sparse10和dead-first/one-credit在两项完整基准中均为0，但定向测试已覆盖。三个计数的单位和条件不同，不能相加当作损失周期。

[完整基准报告](../../../results/ai-cq-timing-20261008/candidate/BENCHMARK-COMPARISON.md)及[完整计数与分布](../../../results/ai-cq-timing-20261008/candidate/benchmark-comparison.json)。两个基准并行的宿主耗时约53.15分钟，此时间不作为RTL性能指标。

## 真实综合与STA取舍

完整R64SystemTop、实际数组标准单元映射、icsprout55 TT/1.2V/25C、1ns约束、0.05ns uncertainty、ABC600ps、fanout8，保持工具/脚本/约束/库身份。原生make sta完成综合、check 0 problems、网表导出和OpenSTA；返回码2来自原timing checker的真实FAIL，没有工具失败，没有blackbox或额外时序例外。全过程约43.50分钟，标准export峰值约8967MiB。

| 指标 | 基线 | 候选 | 变化 |
| --- | ---: | ---: | ---: |
| 单元面积 / μm² | 3,144,021.999995 | 3,142,155.239995 | −0.059375% |
| 全局setup WNS / ns | −2.119304419 | −2.164543390 | 退化45.238971ps |
| 全局setup TNS / ns | −137753.000000 | −137741.593750 | 改善11.406250ns |
| 全局hold WNS / ns | −0.036660694 | −0.036660694 | 不变 |
| 全局hold TNS / ns | −0.087889202 | −0.087889202 | 不变 |
| 负hold端点 | 3 | 3 | 语义一一对应，无新增/消失 |
| 原1ns timing判定 | FAIL | FAIL | 均未通过 |

目标输入路径有实质改善，输出路径则付出代价。以下为真实对应端点组的最差setup slack，单位ns：

| 路径组 | 基线 | 候选 | 变化 |
| --- | ---: | ---: | ---: |
| CQ payload输入D | −2.111715555 | −1.302782774 | 改善808.932781ps |
| CQ payload ICG使能 | −0.936215937 | +0.326810688 | 改善1263.026625ps |
| CQ→WB payload/tag | +0.489983857 | +0.155513659 | 退化334.470198ps |
| CQ→WB accepted | +0.013875512 | +0.029436233 | 改善15.560721ps |
| CQ→WB certificate | −0.292893618 | −0.478821874 | 退化185.928256ps |

真实网表通过full_flush驱动pin查询及独立fanin检查，证明基线到596个CQ payload D和4个payload ICG E的取消路径在候选中消失；候选max/min均无路径。两版owner-control仍有flush路径作为阳性对照。没有用false_path隐藏取消或reset。

全局最差端点由event_before_q[0]转为effect_q[14]：基线经过full_flush→kill_mask→event_select；候选经过full_flush→cancel_candidates→forward_query.out_valid→mem_valid→mem_ready→effect。两个极值捕获端点不同，45.238971ps不是同一FF延迟的变化；仅凭这两条最差路径不能证明变化由共享扇出、门尺寸或其它映射因素中的哪一个引起。

[完整物理对照](../../../results/ai-cq-timing-20261008/PHYSICAL-COMPARISON.md)保留六组输入的all/Q-only setup与hold、CQ→WB、全部负hold语义匹配、原始逐门路径和网表信号解释。所有负hold仍为基线已有的CLINT reset、fabric reset和同80个FF的request_queue ICG。

这是布局前映射测量，不是布线后签核或功耗资格化，不能用cycles×(1ns−WNS)推算真实运行时间，也不能据局部改善宣称整核时序提升。

## 实测回访与裁决

[实际回访材料](measurement-request.md)已在同一新Pro会话提交，明确完整CoreMark、全部物理事实以及发送当时Dhrystone尚未结束，并要求按Dhrystone保持周期不变这一条件作出保留/淘汰判断。之后Dhrystone已完整通过且计数不变，条件已得到实测满足。

[Pro完整实测裁决](measurement-response.txt)明确：若Dhrystone自然PASS且周期不变，仍淘汰C并恢复B；最终实际结果满足这一条件。网页原回答保留其发送/回答时的“Dhrystone待结案”状态，不改写历史消息；本报告使用随后得到的完整结果。[裁决截图](final-decision.png)保存该条件与决定。

这是一项工程取舍：C的面积和TNS略好，不能说它被B在所有维度严格支配；但没有程序周期收益，全局WNS更差，CQ输出侧也有代价，因而不接受本轮完整联合实现作为新基线。不能将已经完成的候选事后改称“还要另一个未定义大改造才能获益的中间态”。

机制层面的有效认识保留：取消前候选与真实capture可以分层，正常完成级数可以保持，目标full_flush宽数据锥可切断。未兑现的是这组联合改动带来值得保留的整核物理收益。当前测量也不能证明CQ没有吞吐瓶颈，因为本轮没有提高其正常吞吐作反事实实验。

## 恢复与交付状态

候选的两个生产文件、相关测试和观察代码完整保存在[candidate-src](candidate-src)，生产/支持patch、冻结RTL、原生网表、真实PASS/FAIL及完整日志保留。恢复前逐文件检查候选未被他人改动，再从本轮开始快照恢复。本轮新增的固定槽专用测试已归档并从活动测试目录移出；没有摘取未经独立验证的候选局部回主树。

[恢复核对](../../../results/ai-cq-timing-20261008/restoration.json)确认108个vsrc文件和189个sim/testbench支持文件全部与本轮前逐字节一致。没有git reset、提交、推送或覆盖前轮修改。恢复后的system-lint及五项直接测试（lsu_completion、completion_payload、lsu_event_count、lsu_network、lsu）全部PASS，见[恢复验证](../../../results/ai-cq-timing-20261008/restoration-checks/RESULT.json)。首次lint调用目录错误、目标不存在的失败日志保留；修正到原sim入口后通过，没有改RTL或降低lint规则。只读配对诊断也已完成，见下文。

Pro建议追加的有界诊断仅复用两份已有网表：将effect、RR历史、CQ owner/control和WB certificate按相同语义配对，并查看两版全局前32个不同端点，区分基线本身的共同限制与候选特有退化。该诊断服务下一轮选型，不改当前淘汰裁决、不修改RTL、不重新综合或运行完整程序。


## 配对诊断的关键结果

[完整配对诊断](../../../results/ai-cq-timing-20261008/paired-path-diagnostic/RESULT.md)及其逐点/分段数据已完成，复用两份现有网表、原库与约束。两版各自global指标与原报告精确一致；同语义实际DFF的对应查询为：

| 同语义端点 | 基线setup slack / ns | 候选setup slack / ns | 变化 |
| --- | ---: | ---: | ---: |
| event_before_q[0] | −2.119304419 | −1.483735442 | 改善635.568977ps |
| effect_q[14] | −2.020954609 | −2.164543390 | 退化143.588781ps |

在effect[14]各自同一条真实最坏路径上，两版均经过cancel_candidates[15]→forward valid→mem_valid→mem_ready。到mem_ready的累计arrival只增加4.049301ps；mem_ready→effect D尾段从452.170133ps增加到601.916551ps，增加149.746418ps。slack还包含required时间，不能只把arrival增量当作slack差。这说明该对应路径的主要新增延迟在后半段，不支持直接归因为前段取消传播变慢；仍不能仅凭此拆分归因到某个具体RTL子改动。

基线20/20个effect和5/5个实际RR历史FF的最差路径均从reset经过full_flush；基线最坏32个不同端点中1个RR、1个effect、30个指定配对族以外端点，族外最差为CQ payload external_result[43]，slack −2.111715555ns。六个仲裁来源并不等于六个历史FF，event_before_q[5]为常量，被综合删除。

这些结果供下一轮网页架构选型使用，不能单凭候选特有退化就让主树追逐新热点。本轮淘汰C的裁决保持，未启动第三份RTL、重综合或新的完整基准。


两版有效配对分析均返回0，原全局指标精确一致；初次采集的PathEnd对象生命周期错误及工具崩溃日志保留，修正采集顺序后完成，未修改RTL、库或约束。当前无遗留仿真/综合/STA进程。本轮文件链接与git差异空白检查通过。
