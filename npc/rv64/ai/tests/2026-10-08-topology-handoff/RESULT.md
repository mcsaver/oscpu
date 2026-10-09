# 完整拓扑驱动的网页 Pro 架构设计交接

交接阶段状态：**网页完整设计回答已收回，落地前关键源码核查完成。**
后续执行已落实为[第三轮完整实验](../2026-10-08-round3-cq-value/RESULT.md)：完整基准获得周期收益，但全局时序目标未达，联合候选不保留并恢复 B。
下文“未实现/未测量”等陈述记录交接时刻，不能覆盖后续实验结果。
页面显示“思考了33m 23s”和“回答已完成”。已保存十节正文、表格和伪RTL；没有把生成过程中的候选当最终方案。
本轮完成的是拓扑驱动设计交接，不能标为已完成R3优化实验或已取得新性能收益。

## 网页选出的设计

[完整回答](response.txt)比较了三个候选：

| 候选 | 网页裁决 |
|---|---|
| 同拍取消发布 + CQ确值旁路 | 选择为R3：`LOCAL_CANCEL_PUBLISH + CQ_VALUE_BYPASS` |
| 删除LSU完成汇聚级，六个生产者直接参与WB | 不选；WB由九源增到十三源，局部排队收益尚无证据，输出选择代价较大 |
| store地址/数据分离调度 | 保留为后续候选；当前ready时差未知，且不直接处理共同取消关键路径 |

R3新增两条结构能力：

- 从CQ front中已经完整形成的成功普通整数load结果，独立于WB grant提前唤醒IQ并向RR供值。
  load正式完成、PRF写入和ROB完成资格仍走原WB路径；无争用时目标是消费者issue/read提前一拍。
- 在原Commit事件更新边沿产生同拍publish寄存投影，把全清与partial cancel分开发往LSU最终资格处。
  不延后一拍flush；覆盖query、physical、owner、完成等使用侧，目标是缩短多个近最差路径共有的取消前缀。

保持当前两lane front/skid CQ、六源dense-prefix仲裁、九源WB及既有事务容量。
候选CTL-05/BE-10仅是拟议ID，未混入当前生产拓扑。

## 本地核查结论

[完整源码核查](LOCAL-REVIEW.md)支持一拍机会和同拍发布更新式，未发现必须替换网页架构选择的结构性阻碍。
实现前已明确五项适配：新增两路grant-independent ROB查询；覆盖DEFER_READY及移位量预计算；
修正canonical kill的valid mask公式；ticket/value_ok在LSQ释放前随owner带走；补算RR实际数据快照成本。

网页269 bit只覆盖ticket/发布位；若RR按现有结构由四源直接扩六源，还增加804 bit快照，合计1073 bit声明增量小计。
这不是综合面积预测。此前最坏路径不会因增加publish信号名就自动改善，需要实际mapped STA。

网页提出的实验保留目标是：两个完整基准周期均不增加且至少一个降低0.5%，全局setup WNS改善至少0.10 ns，
setup TNS和hold不恶化，正确性与真实消费者提前得到验证。**这是网页建议的实验裁决目标，不是实测收益，
也不替换仓库既有correctness/正式PPA规范。** 当前保留B仍为CoreMark 8,968,518、Dhrystone 14,267,505 cycles，
setup WNS −2.119304419 ns；本轮没有更新这些测量，1 ns仍为FAIL。

交接时给出的后续范围是：按修正合同实现完整 R3，用两个开关做小范围消融，再测一个完整 R3 的完整程序与同约束 STA。
该范围已在后续第三轮执行，见上述实验报告；本记录继续保留原设计交接事实。

## 会话与实际材料

- 会话：[RV64架构设计交接](https://chatgpt.com/c/6ac75b60-4c68-83e8-a930-6b7172a0aec4)。
- 发送前UI确认：GPT-6，Pro第5/5项；新会话，无本地预选方案。
- 任务：[request.txt](request.txt)。
- 实际附件：[当前拓扑](uploads/rv64-current-topology.txt)（143,503 bytes）、[测量与合同](uploads/rv64-measurements.txt)（72,936 bytes）。
- 首次拓扑上传网络失败后仅重传失败附件；两份完成后发送一次。原附件保持原样。
- [发送截图](uploaded.png)、[完整回答可见文本](response.txt)、[完整回答无障碍状态](response-ax.txt)、[完成截图](response-complete.png)。
- 本次复制按钮显示成功但剪贴板返回旧提问，未采用；改从可见Conversation正文提取，核对十节、代码换行和末段结论。
- [consultation.json](consultation.json)记录回答完成；[旧等待截图](web-status.png)/[旧等待状态](web-status.txt)保留为历史。

## 已完成的拓扑与工作流更新

生产文档为全核+七域，FE8、BE9、FP6、CTL4、MEM7、LSU12、BUS5，共51个设计单元，含状态归属、寄存边界、
容量/信用、取消/副作用与UNKNOWN。全核旧9月数字标历史，修正FP Fast数值完成位置、RAS确认前缀、Align owner和Memory已有pending write。

- [工作流](../../README.md)、[设计单元约定](../../topology-contract.md)、[输入模板](../../consultation-template.md)。
- [导出脚本](../../export_web_context.py)默认写build/ai-web-context；不联网、不覆盖实际已上传附件。
- 上轮[validation.json](validation.json)验证93份生产源码/header/filelist与已测基线相符及文档/导出通过；
  它不代表R3正确性或收益。本次只回收设计、核查源码与方程、更新记录，未改RTL/测试/SDC，未运行新仿真/综合/STA。
