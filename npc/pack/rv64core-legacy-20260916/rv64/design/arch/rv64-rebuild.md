# RV64 原生 RTL 重写

本任务按用户要求几乎从头重写整个乱序核，借鉴手写IFU的分级、固定槽和显式事务归属风格。
默认工程使用 `vsrc/rebuild` 原生核，没有旧核实例或双核选择器；旧Ooo*优化方向不再作为待办。

目标是理想双发射／双退休稳态CPI 0.5，并以 **1 GHz / 1 ns / icsprout55 TT** 为时序里程碑。
正确性、实际程序周期、时序和面积共同约束结构选择。当前只推进CPU core，不跑OS；
完整Tensor/NPU验证与优化暂缓，已有接口保留。Sdtrig已加入ISA范围，官方断点用例必须通过。

**最新联合33的完整CPU功能回归通过，整核1 GHz尚未通过；本轮已启动的小任务均已收尾，现按用户要求暂停。**

完整暂停范围、单点取舍和已暂缓的工作见[本轮暂停记录](rv64-rebuild-pause.md)。

当前默认为 `tmp/rv64-rewrite-timing-28` 的85份冻结RTL。112项主模块、全部相关矩阵、
8项整机定向、352项软件、两个基准及真实整核理想吞吐均通过。
默认仿真／综合filelist与冻结源相同，严格lint与新测试入口检查通过。
当前同源整核1ns原始映射为setup −3.472463846ns、hold −0.036660694ns、面积3,151,497.72µm²。
真实单元与hold修复均已完成：setup −1.543375254ns、hold +0.005088600ns、面积3,615,844.96µm²，
连接／逻辑核对通过，1GHz仍FAIL。相对timing27最终同flow结果（−1.490287662ns／3,610,896.24µm²），
28的setup退步53.087592ps、面积增加4948.72µm²，两个基准周期完全不变；28不具备PPA改进资格。
默认只是开发入口。冻结29／30／31的整核布局前PPA已完成且均未通过1GHz。
31最终setup−1.882808447ns、hold+0.005088600ns、面积3,605,016.80µm²；
双基准全部六项终态计数与30一致。32原始PLIC检查失败保留；32a修正该仿真断言的冻结条件，
可综合硬件与32相同，139模块及矩阵、352软件（含PLIC和官方断点）、8整机、7个理想窗口及双基准全部通过。
32a整核raw setup−3.473068953ns、hold−0.036660694ns、面积3,144,771.56µm²，
按用户要求尚未运行后续布局前单元优化与hold修复。

联合33将解析证书、普通load排空、CQ写回预约、cached store直接WRITE合并为86源／9文件，
相对32a新增普通流水沿和逻辑状态均为0。严格lint、146模块及全部相关矩阵、352软件、
8整机、7个CPI 0.5窗口与两个完整NEMU基准通过。
CoreMark为9,813,100拍／CPI3.048944，Dhrystone为15,703,314拍／CPI3.685644，
相对32a周期分别下降3.2768%／5.9410%。CoreMark的时间输出也改变了少量退休指令与访存计数，
这些是同程序实测总周期，不能表述为完全相同动态指令流。
33的整核综合按用户暂停要求未启动；局部闭包结果不能替代该整核PPA。


## 架构与事务边界


| 模块 | 当前85源默认开发组合 |
| --- | --- |
| FetchStream／ITLB入口 | 16-byte packet，4个transport owner；独立IF翻译采用lookup、walk descriptor及两个响应槽，最多3个已预留请求；poison与完整请求一起保存，接受后按序排空 |
| 对齐／预测 | 两个packet入口槽、三个固定map owner；预解析8个半字起点，双2/4/8-byte输出；8项speculative RAS；A/B/C明确归属和old-Q预测快照 |
| 静态译码 | 编码控制35bit在现有 A→B 边沿生成；顺序 NPC 使用预测准备已算好的真实 PC+length；C 同 owner 保存，不增加流水级 |
| 后端译码队列 | 4 个固定指令槽、双入双出、可部分派发；Q 态容量信用隔离资源反馈；LSQ容量查询只读Decode Q，真实birth仍保留clear／stop／kill资格；非法指令 TVAL 在固定槽重建，fetch fault 保留原 TVAL |
| Rename／ROB | GPR/FPR各64物理寄存器；32项ROB；双分配／完成／提交；完整tag为generation4+slot5。Serial分类另存两个head/head+1位；双退休前瞻及同槽新生旁路保持原拍数，无效槽保留与META相同的载荷语义 |
| 恢复 | 杀年轻指令，每拍逆序undo两项；older事务继续完成；外部未drain的owner阻止slot重用。ROB本地冻结采用已有分支Q态pending；实际kill、resolve与undo事件仍由原完整判定产生 |
| Issue／PRF／RR | 16固定槽，newborn下一拍完成就绪初始化；4 GPR／3 FPR读口。RR采用两个终端槽与一个入口槽的Q态容量，保留held取消、完整tag与原owner预算。FPR压缩地址在完整IQ原始选择对上准备，取消lane可产生无owner空读，真实fire与三读口预算保持；新生源仍检查真实ALU旁路及PRF状态 |
| MEM 派发 | ROB、rename、IQ、LSQ 原子分配；Q-only 空槽、双 lane 前缀；Execute 按RR原物理lane直接以slot/fulltag绑定，去掉MEM年龄排序及密集跨lane交换；LSQ预约仍按程序年龄 |
| LSU | 20项；older未绑定MEM保持顺序屏障；请求队列仅以Q占用与真实pop／kill决定head，去掉故障返回到head的依赖；非对齐RAM分片只有一个最终完成；完成队列空载荷按Q空槽提前准备，原valid／credit／kill与held数据不变 |
| 翻译返回 | 每lane两个未接受入口owner加四个真实接受FIFO；read/write/size/AD随完整tag保存。D侧分离lookup与outcome，由实际LSU预约保证Protection接纳，payload按Q态准备；通用模式仍允许任意返回背压。PMA范围事实随owner保存，lane0→lane1→local-check优先级保持 |
| FP入口 | 两个239bit固定owner槽，输入信用只来自Q态空槽；真实kill/pop不能同拍借出满槽。普通空槽延迟与持续II1保持，动态FRM/合法性随实际接受捕获；Fast/FMA按Q-owner预启动，取消命中的死事务仍占用真实槽直到排空 |
| 整数执行 | 双ALU；流水乘法／CLMUL、迭代除法；长运算入口预资格化。Serial／FP／MEM原始Q owner先选完整载荷，真实fire仍保留kill／flush与canonical检查 |
| 浮点执行 | 原生 S/D FMA、DIV/SQRT、转换／比较／舍入；SoftFloat 独立数值 oracle |
| ICache／取指保护 | 8 KiB，两路，64-byte line，同步128-bit sector读；四word的PMP overlap/deny及PMA/模式摘要随请求和overflow保存，两个固定130bit保护事实槽独立完成首匹配，只复用8bit结果；16B PMA上界常量化，同边沿预解析header，普通命中/恢复不增加拍；256个方向计数器按各行Q本地饱和更新，old-Q预测语义保持 |
| 访存服务 | 每条物理lane两个固定请求槽，真实Q占用隔离Cache ready回传；固定顺序仲裁保留CPU稳定槽与AUX响应消费前的busy，支持lane1独立接受 |
| DCache | 8 KiB，两路、PA bit3 双 bank；四个256×64 1R1W数组；异 bank 命中 load 支持双完成 |
| Store／AMO | ROB head精确授权；普通AMO归一化→两个32位部分结果→合并，较旧结构增加两拍；普通load/store、LRSC及PTE CAS不增拍。真实B成功后完成，错误保留旧值 |
| MMU／PMP | 双 DTLB、独立 ITLB，Sv39、PMP×16；三个 walker 经共享 DCache 读 PTE 和 A/D CAS |
| CSR／提交 | CSR RMW入口快照、提交生效；head Serial／已完成异常阻止年轻新生，精确副作用仍在提交授权。M/S外部中断源独立；WFI可等真实CLINT deadline |
| AXI | 实际 ID/LEN/RLAST，4 read／2 write owner；AW/W 独立保持；fabric 向 Lite 端点逐 beat 转换 |
| 平台 | CLINT、PLIC、UART、Goldfish RTC、syscon；现有协处理器接口保留，完整Tensor/NPU工作暂缓 |

保留 RV64IMAFDC、Zba/Zbb/Zbc/Zbs、Zicsr/Zifencei、M/S/U、Sv39、PMP×16、
Svnapot 及 Tensor 接口。Sv48/Sv57、Svrsw60t59b 不属于本核能力。
本轮 Sdtrig 实现一个 native 地址触发器：tselect=0，type6，同时支持既有 debugger 的 type2；
支持执行／load／store、M/S/U 模式、最低虚拟字节地址相等匹配和精确 breakpoint exception。
未实现的 action/select/match/chain/size/dmode/hit 功能按 WARL 约束读回。
具体 CSR 行为和异常路径由 R64Trigger、R64Csr、CoreTop、LSU 及专门用例共同验证。

派发时分配 LSQ 后，RR 不再保存第二份 MEM 预约环，也不以 IQ 离开发射时的减法信用重新推测容量。
Execute 的 bind 必须同时匹配 slot、完整 ROB tag、live 和未绑定状态；旧 generation 不能污染新 owner。
取消的外部已接受事务必须排空。完整 idle 包含未绑定 owner；
仅用于 head Serial 的 drain_idle 忽略年轻未绑定预约，但仍包含所有已绑定、翻译、物理和终端事务，
避免 SFENCE 与年轻未绑定指令互等。

普通非对齐 RAM 支持2/4/8-byte各偏移及缓存行交叉；翻译开启时跨4 KiB页可返回 alignment trap。
分片 store 只在 head 执行，错误时已写出的片段不回滚，TVAL 指向失败字节。
IO／原子非对齐按接口合同报错。AXI 错误不能伪装成成功。

## 验证结果与范围

C++逐条比较真实退休指令的全部GPR/FPR，在完整退休前缀后比较确定性CSR，UART按字节比较。
SV TestTop只寄存实际退休观察，不向综合硬件复制架构状态。
时间／计数器读取只同步该条指令的目的寄存器，不通过恢复整份参考CPU状态跳过失败。
RTL断言、AXI错误与非法owner检查始终生效。

| 当前85源 | 结果 |
| --- | --- |
| 严格lint／默认filelist | PASS；全部85源逐文件相同 |
| 原生模块 | 112/112主回归PASS；取指事实槽复位已纳入主入口 |
| 相关矩阵 | 既有负例、7项pipeline、store、16种访存admission、trigger、4种RR终端配置、FP满槽准入负例及原始容量查询矩阵全部PASS |
| 整机定向 | 普通、Sv39、Sdtrig、官方breakpoint，各正常／背压模式，共8项PASS |
| 非OS软件 | AM74 + official177 + ACT4 101 = 352/352 PASS |
| 全核理想吞吐 | 7个热区均768条／384拍，逐拍双退休，CPI 0.5；完整NEMU对照 |
| CoreMark | 3,218,524条／10,032,450拍；CPI 3.117096532 |
| Dhrystone | 4,260,670条／16,584,643拍；CPI 3.892496485 |
| 同源整核1ns综合／STA | 最终真实单元与hold修复：setup −1.543375254ns、hold +0.005088600ns、面积3,615,844.96µm²；1GHz FAIL |

相对timing27，两基准的全部退休、周期、双退休、trap与AXI读写计数精确相同，完整NEMU对照通过。
CoreMark总线为2416读／148105写；Dhrystone为1191读／601192写。
宿主运行时间不作为CPU性能数据。

整核吞吐程序使用真实SystemTop、取指与缓存／AXI路径。4KiB独立整数指令体自然预热后，
连续6轮完整循环为1024条／512拍；7个热循环中段均为768条／384拍。
首次冷取指为3347拍，最后循环末尾与退出分支重叠为522拍，均保留。
该结果只说明理想稳态能力，实际基准CPI仍如上表，不能称为通用应用CPI 0.5。

ACT4的101项ELF由ACT4/Sail按本hart配置生成，关闭未支持的Svrsw60t59b。
官方177项包含Sdtrig breakpoint；AM为当前源码74项。测试源码、签名和失败项没有删改。
小型linux-mini-boot是裸机Sv39/SBI测试，不作为OS启动。
SoftFloat提供浮点独立数值oracle；AXI反例检查真实ID、LAST、早到B和无owner响应。

常规入口见 `npc/rv64/README.md`：`make -C npc/rv64 regression` 只包含CPU；
完整 `tensor-test` 是独立可选入口。当前点的输入、命令和结果位于
`tmp/rv64-rewrite-timing-28`，主要索引为 `current-result.json`、
`system-result.json`、`tests-result.json` 与 `default-filelist-binding.json`。

## 时序与面积的判定

同一RTL以实际标准单元映射，所有算术与cache数组可见，不使用理想SRAM、占位黑盒或reset/kill假路径。
完整SDC为1ns时钟、50ps setup/hold uncertainty、400ps I/O预算和20fF输出负载。
当前映射使用ABC600ps／FO8；实际单元面积按导出的flat STA网表和Liberty计算。
物理缓冲／尺寸修复后核对原单元逻辑与连接，不靠放宽约束获得通过。
目前仍是布局前结果，没有CTS、布线或寄生提取资格。

| 已完成的比较点 | setup／hold slack（ns） | 实际单元面积（µm²） |
| --- | --- | --- |
| timing22原始映射，82源 | −3.433340311／−0.036660694 | 3,210,217.08 |
| timing22真实驱动／尺寸修复 | −2.002177715／−0.036415558 | 3,698,747.08 |
| timing22补真实hold buffer | −2.002177715／+0.005088600 | 3,698,907.24 |
| timing24原始映射，旧84源 | −3.433340311／−0.036660694 | 3,206,164.92 |
| timing24真实驱动／尺寸修复 | −1.665419459／−0.036415558 | 3,703,274.40 |
| timing24补真实hold buffer | −1.665419459／+0.005088600 | 3,703,434.56 |
| timing26旧85源原始映射 | −3.472463846／−0.036660694 | 3,148,120.08 |
| timing26真实驱动／尺寸修复 | −1.593550801／−0.036415558 | 3,612,295.40 |
| timing26补真实hold buffer | −1.593550801／+0.005088600 | 3,612,455.56 |
| timing27旧85源原始映射 | -3.472463846／-0.036660694 | 3,148,817.56 |
| timing27真实驱动／尺寸及hold修复 | −1.490287662／+0.005088600 | 3,610,896.24 |
| timing28当前85源原始映射 | −3.472463846／−0.036660694 | 3,151,497.72 |
| timing28真实驱动／尺寸及hold修复 | −1.543375254／+0.005088600 | 3,615,844.96 |
| timing29真实驱动／尺寸及hold修复 | −1.676127076／+0.005088600 | 3,628,971.36 |
| timing30真实驱动／尺寸及hold修复 | −1.893222690／+0.005088600 | 3,607,802.52 |

timing24最后一步以143个正向缓冲修复161个hold端点，未允许新增setup违例，完整原逻辑连接图等价PASS。
相对timing22最终点，setup改善336.758ps，实际面积增加4527.32µm²，两个基准周期完全相同；setup仍不满足1ns。单模块通过不能替代整核通过，各局部收益不能相加推导最终结果。
timing26最后加入143个真实正向hold缓冲，setup未变。相对timing24最终点，setup改善71.869ps，
实际面积减少90,979.00µm²（约2.46%）。timing26最终关键路径为RR终端owner→MEM操作数交换→AGU→LSU检查事实；
另有Serial发射许可→IQ选择→RR压缩FPR地址，以及kill→LSU完成仲裁→终端写入使能。
未测量的功耗保持未知。

## 已定位的问题与后续结构选择

timing23曾加入63个物理GPR持久就绪位，真实软件暴露事件覆盖漏洞：
弹出A后B成为ALU可旁路head，同时接收C；原early口优先发布C，B未被持久事实记录。
AM7、ACT4 33及两个基准均被原live IQ初始化断言拒绝，尽管95个模块测试通过。
真实ROB／Rename／ALU队列已形成117ns定向反例。timing24精确撤回该3文件改动，
恢复真实holder旁路检查，完整352项重新执行后全通过；失败项没有列为不适用。
诊断及反例位于 `tmp/rv64-short-ready-debug`，原失败点仍保留源码、可执行程序和原始日志。

改进的next-head发布研究点覆盖原事件漏洞，并与CLMUL原始Q载荷准备完成组合验证。
真实Backend+Commit闭包修复后，相对timing24的setup从−1.476684809ns变为−1.509283185ns，
面积增加10,507.56µm²；该组合未进入默认。真实query/CLMUL路径有改善，但RR新路径退步，不能以局部收益代替完整结果。

旧84源最终整核最坏路径为分支取消资格→FP ingress ready→Execute ready→RR terminal计数；
另有LSU返回信用→Cache接收→LSQ状态，以及IF翻译响应选择→PMP保护→ICache fault。
timing26组合处理这三条控制边界，并将AMO长运算分段；其整核同源结果见上表。

局部匹配证据支持这一组合：FP完整Backend+Commit+FP映射setup改善138.198ps、面积增加2817.64µm²；
Service实际修复setup改善98.204ps、面积增加4620µm²；完整取指闭包实际修复setup改善497.635ps、
面积减少83,265.28µm²。普通AMO各运算段及新增ICG已有正余量，完整Cache面积增加2458.12µm²。
这些数字不可相加推导整核结果；各独立闭包仍未全部通过1ns。

当前timing27的完整联合块为MEM固定物理lane绑定、Fast/FMA预启动、两个ROB头Serial缓存位，以及
取指PMA常量范围／同边沿header／固定保护事实槽。全部源合并后已重跑完整CPU验收，基准无周期变化。

局部匹配测量保持各自范围：Fast/FMA完整Backend+FP+Commit真实单元修复后setup从−1.475540876ns
到−1.471156836ns，面积减少159.04µm²；该闭包最坏路径已转为旧Serial读取到提交flags，不能据此推断整核收益。
独立ROB头分类原始映射增加两个FF、面积增加3115µm²，retiredNPC端点改善240.347ps，但全局退步41.576ps；
它与FP、MEM改动共同进入本次整核测量，单独不称通过。
取指累计PMA／header／事实槽的完整闭包setup为−0.289553165ns；相对初始timing26取指闭包
−0.596762955ns改善307.210ps，面积从1,012,468.52µm²到1,012,066.16µm²。该子系统仍未通过1ns。

Fast/FMA的新数值预启动保留死owner的真实资源占用；FMA满槽取消定向中较老请求受到额外背压，
最后有效结果晚一拍。无取消连续运算保持II1，整核基准和理想窗口计数不变。测试保留这项代价。
raw LSQ容量查询、raw FPR地址分配、LSU空闲完成槽载荷准备及分支预测器行内计数器更新已构成当前timing28；完整功能与PPA状态见下文。

timing25初次合并的System严格构建发现Service三辅助端口配置下的恒真比较告警，未开始软件或PPA。
timing26用静态generate折叠整个已知范围，未压制诊断；完整软件和基准重新执行后通过。
冻结脚本曾将make源码变量误当Verilator文件参数，造成此前lint读默认filelist；已修正该传参，
实际冻结24/26源严格lint均重新通过。真正System构建、动态回归和STA原本就传了正确源码列表，
它们的真实执行结果不受此脚本缺陷影响。

已拒绝ROB count预计算、Serial读取置换等只改善个别节点却让整体时序或面积退步的实验。
详细历史证据留在对应 `tmp/rv64-*` 目录；本文件只维护当前结构与可比较结论。
已完成且过时的编译中间物按用户要求清理，保留当前执行所需文件与结果报告。

### timing28的完整联合边界

相对timing27只修改Backend、RegRead、LsuCompletion、Predictor四个RTL文件：分别完成Decode Q容量查询、
原始FPR地址分配、空完成槽载荷准备、按行预测计数器更新。新增状态和流水拍均为0，
完整两个基准的退休／周期／双退休／异常／总线计数精确相同。
无owner槽预写和取消lane空读可能增加翻转，功耗尚未测量。

匹配局部量测保留其真实成本：Completion-only在实际20槽LSU中的全局physical setup基本不变
（−.853105426→−.853107452ns），面积增加292.60µm²，4个完成载荷ICG enable均转为正余量；
预测器改动的完整ProtectedFrontend setup改善9.588ps、面积增加3718.40µm²。
这些不是整核收益，也不能相加推导整核频率。额外LSU cancel-facts、Serial原始查询、
head NPC投影与后续AGU/失效事件研究均为独立私有实验，未加入冻结timing28。

候选timing29已经固定为85源／9文件的五块联合设计，含resident AGU、head NPC、原始Serial查询、FENCE.I事件失效和LSU双forward槽。严格lint、119项完整模块与配套矩阵、352软件、8项整机定向、两项完整基准及7个CPI0.5热区均PASS。CoreMark／Dhrystone的周期、退休、双退休、异常和总线计数相对timing28全部精确相同。同源整核raw完成：setup−3.472463846ns、hold−.036660694ns、面积3162745.32µm²，相对28增加11247.60µm²；真实单元与hold修复已完成：setup−1.676127076ns、hold+.005088600ns、面积3628971.36µm²；尚未替换默认timing28。逻辑新增305bit、无普通流水增拍，实际DFF净增304。相对28同flow setup退步132.751822ps、面积增加13126.40µm²（两边最终hold修复也增加相同160.16µm²），不能按局部组改善推广。


匹配的Backend+FP+Commit闭包真实单元修复已完成：timing28的原始容量／FPR查询组合相对其父点，
global setup从−1.482471347ns到−1.442905784ns，改善39.566ps，面积减少9.24µm²；
FPR地址组只改善0.040ps，retired NPC组改善39.514ps。仍没有1ns通过。

同一新闭包基线下，单独raw Serial查询真实修复后global为−1.463717461ns，退步20.812ps，
面积增加492.80µm²；单独head NPC投影为−1.613616347ns，退步170.711ps，面积增加5840.80µm²，
FPR组退步286.920ps。两者的负项保留，不能引用不同旧wrapper的数字制造单项收益。
这两个切片属于已固定timing29联合设计，是否保留由其完整结果判断。

resident AGU的完整Backend+FP+Commit+20项LSU闭包原始映射，真正head经AGU加法至地址状态D
改善329.529ps；不限算术的head控制路径退步14.421ps，global退步23.031ps，实际面积增加2037.84µm²，
seq与流水拍数不变。该闭包的匹配真实单元修复已完成，完整正负结果见后文resident AGU段。
后续独立研究为ROB单热行读取、现有取指facts槽内PMP分段事实，以及独立A/D重走准备owner；
它们均在私有目录，不扩张冻结timing29，也不提前宣称完整性能结果。


后续两个私有完整切片未选入：PMP分段事实新增578FF，完整前端raw global不变，
PMP输入至facts改善226.684ps、facts后级反而退步307.866ps，面积增加4069.24µm²。
单独A/D replay准备新增21FF，消除了head至普通翻译队列控制D的组合路径，但LSU raw global
退步48.297ps、面积增加1011.92µm²；固定lane0使一个lane0 held16拍而lane1空闲的真实重走
从2拍变18拍。这些结果均不加入默认或冻结timing29。后续会研究真正的保护决策流水边界和请求选择边界，
同时度量普通指令周期损失；不会以目标子路径改善替代完整结果。

已清理timing28完成后的369份可再生编译中间物，共541,200,994字节，保留仿真可执行程序、
全部源／命令／日志／结果及正在运行的综合与STA输入。


公开方案参考继续用于寻找结构边界：BOOM文档将ROB按提交宽度分bank并压缩每行PC，
还只保存最老异常的完整载荷；这说明控制状态和宽读取应围绕真实消费者组织，
不能仅复制多个宽队首缓存。[BOOM ROB文档](https://docs.boom-core.org/en/latest/sections/reorder-buffer.html)
这些做法尚未照搬到本核。其执行文档还将立即PC重定向和延后一拍的kill广播分开；
本核正在单独分析如何在现有完整tag、undo及不可撤销AXI合同下采用相应边界，
尚未改变实际取消延迟。[BOOM执行文档](https://docs.boom-core.org/en/latest/sections/execution-stages.html)


后续ROB单热行读取只替换现有头部读取拓扑，匹配Backend+FP+Commit raw global改善81.975ps、
面积减少20821.08µm²；逻辑增加32bit，实际DFF净增27，ICG数不变。
但raw head NPC/Serial缓存D分别退步126.888/172.118ps。匹配真实单元修复后global改善156.226277ps（−1.617795229→−1.461568952ns），面积减少28660.52µm²；head NPC/Serial D仍分别退步34.837/102.322ps，retired NPC改善381.437ps。两侧hold均−.036415558ns，仍没有1ns通过。

Dcache写载荷准备仍使用原64bit寄存器、无新增流水拍，actual64-set双实例全协议/AMO对照通过。
actual20 LSU+8KiB Cache raw的64写载荷D从−1.149481ns到+0.007768ns，ICG E从−.934374ns到+.413796ns，
reset至两组均无组合路径；全局却退步12.683ps、面积增加10363.92µm²，需保留真实代价，不能据局部组宣称通过。

真正新增一级的取指保护实验，实际4槽System+NEMU维持7×768/384热区CPI0.5；
同一个完整吞吐程序8232条从7211到7280周期（+69），冷body增加63拍。
所以选择现有4槽，不无依据扩大为8槽；净逻辑状态+713bit，完整前端raw实际DFF+729、面积+4406.36µm²，global仍−1.500107646ns；PMP至facts由−.269345到+.038545ns，全体新增payload最坏−.248759ns。
恢复登记和LSU请求owner实验在独立目录实施，不扩张冻结29或替换默认28。


timing27整核真实单元修复及hold收齐：setup−1.490287662ns、hold+.005088600ns、
面积3610896.24µm²，原网表与修复网表连通/逻辑核对通过。1GHz仍FAIL。
原完整SDC下7组中，backend−1.490、LSU−1.486、FE−1.204、Dcache−1.126、
Commit−1.062、DTLB−.9589、其余ICG−1.405ns；所有路径取自最终hold修复网表。
该结果是27完整历史点，不冒充当前默认28或冻结29的新结果。

AD任意安全lane完整切片在私有目录增加22个逻辑bit；真实双DataTranslation/PageWalk/Protection验证
表明，初始head6→6拍、预准备2→2、fresh-needsAD3→4，lane0或lane1分别held16拍时均2→2；
双lane都held8拍时11→10。两条已展示的普通请求保持，replay只在空port或实际normal握手沿获取port。
actual/generic取消、两类错误变体、双port手交与接受预算drain通过；完整LSU raw global退步47.8822ps（−.771379232→−.819261432ns）、面积+553.84µm²、实际FF+22；普通TQueue控制消除head组合路径，translation输出组退步35.074ps；
保留fresh+1拍成本，不宣称所有场景零代价或已加入默认。


Dcache载荷切片的完整LoadStore真实单元配对修复已完成：global setup改善270.203531ps
（−1.174488425→−.904284894ns），面积减少1058.12µm²，图等价核对通过。
64目标载荷D在raw曾+7.768ps，修复后实际−55.338ps；ICG E为+.390097ns，
reset至两组仍无路径。hold仍−1.755467ps，不能写成时序全通过。


### timing30完整联合回归
冻结86源／11个改动RTL，父点为CPU完整PASS的29。七项共同启用：ROB单热行读取、
Dcache原写载荷准备、4槽前端真实保护决策级、立即权限与登记取消分离、LSU单热memory owner、
AD重走选择任意安全lane、SFENCE.I以外的SFENCE提交重启事件。
合并后17项定向检查与实际86源严格lint全部通过，134模块及完整旧矩阵和新增AD双port矩阵全部PASS（1342.518s）；
新编译System通过全部352软件／8direct／7理想热区（均768/384），两项完整基准均通过NEMU。
CoreMark为3,218,505条／10,103,257拍／CPI3.139114900，较29增加70,807拍（0.705780%）；
Dhrystone为4,260,670条／16,695,031拍／CPI3.918405087，增加110,388拍（0.665604%）。
CM双退休1,252,142／读2416／写148103，Dhry双退休1,724,489／读1191／写601192，各trap1。
CM退休较29少19、写事务少2，实际计时与格式化输出不同，因此不再声称所有工作负载计数精确相同；
上述周期仍取真实全程序计数，不将guest输出分数或host耗时代替CPU周期。
同一86源1ns整核raw已完成（2614.417s）：setup−3.473068953ns、hold−.036660694ns、面积3150494.48µm²。标准30-pass真实单元修复（4349.364s）及hold修复（224.080s）均完成，最终setup−1.893222690ns、hold+.005088600ns、面积3607802.52µm²，连接／单元逻辑核对通过。相对29最终setup退步217.095614ps、面积减少21168.84µm²；相对28退步349.847436ps、面积减少8042.44µm²。1GHz仍FAIL，30未替换默认，Tensor/NPU没有新工作负载。

原始最坏是共用AXI返回数据经Dcache广播写入阵列，但最终修复后全局已转为resolve_lane Q→当前解析许可→redirect/NOW kill→普通memory offer→ready→LSU state[7][2] D。最终7组为Backend−1.820、Commit−1.347、Frontend−1.380、Dcache−.8829、DTLB−1.102、LSU−1.893、其他−1.836ns；Dcache此时是reset→command_sent，不能再把raw数组广播当作最终全局路径。

30回归中的TB适配只修正私有用例的PASS打印名称，使其匹配统一Makefile严格规则；
首个前端测试原执行已完成1402请求/响应且断言通过，失败来自旧名称。未放宽匹配规则或DUT断言。
mowner主目标明确使用18代际owner-wrap场景，Dcache主目标带late-invalidate。

28完整最终hold网表7组端点已收齐：Backend−1.543ns、Commit−1.062ns、Frontend−1.184ns、Dcache−1.126ns、DTLB−.9389ns、LSU−1.466ns、其他−1.330ns。其全局仍为reset经原Serial许可/IQ选择到FPR地址；对应29/30已改动，不能将28路径当作30实测。


新的私有head-npc-direct-timing30消减实验仅关闭实际Backend的HEAD_NPC_CACHE，继续使用32行单热选择，
去掉128bit重复头NPC投影、保持canonical META和xRET数据规则。完整86源lint与headclass、
连续恢复、旧代际写回定向通过；完整Backend+FP+Commit+20LSU共同wrapper配对raw已完成，global−2.357577324→−2.572625399ns，面积1199311.68→1190059.64µm²；
两边实际REGISTERED_CANCEL/RESIDENT_AGU/HEAD/PREP均启用，icache/SFENCE事件输出可见。128个缓存D端点删除不等于PASS，canonical NPC组反而退步78.808ps，真实global仍是resolve→birth→RAT gmap；不进入下一联合版，冻结30不变。

另清理三个已完成私有试验的19份可再生vvp编译产物，共279,479,259字节，源／结果／活动EDA输入保留。

29最终全核分组：LSU reset→check_rows[1489]D为global−1.676ns；Backend forward结果tag→头NPC投影D为−1.553ns，同起点至ROB count为−1.564ns；Commit−1.175ns、FE−1.091ns、Dcache−1.082ns、DTLB−.877ns。登记取消和去除重复头NPC分别针对前两类实际跨域路径，但私有结果未收齐前不宣称切断或整体改善。

### 冻结30后的零拍拓扑检查

FP双发射端口Join仅在真实固定行Compact计划上去掉多余count地址屏蔽，保留通用模式及全部fire、rank和端口分配；
50位任意真实输入的完整地址/rank等价SAT、严格86源lint、实际RegRead及FP端口矩阵均通过。
ROB恢复许可保留完整tag匹配、当前canonical live/generation及pending取消，在tag相等保护内改为从已有plan_tag读取行；
213位任意权限输入SAT、严格86源lint、六项恢复/提交定向及独立接口review通过。
两者均0新增FF／0拍／0容量变化，分别在同一个真实Backend+FP+Commit+20LSU闭包进行candidate raw，
复用输入完全相同的已完成父30基线（setup−2.357577324ns、面积1199311.68µm²），没有修改冻结30。

后续resolve-owner局部raw已完成：全局setup改善122.534514ps至−2.235042810ns，面积增加550.20µm²；
69,606 DFF与716 ICG不变。plan_tag全9Q后继却退步520.904ps，原始全局仍是Execute resolve→RAT。
相同标准30-pass单元修复已完成：global−1.749422550→−1.766143441ns，实际退步16.720891ps，面积1399438.32→1398498.36µm²（减少939.96），hold均−.036415558ns，连接图核对通过。最终全局在两侧均为resolve_lane→LSU prepared_tag[1]，head NPC／canonical NPC／retired NPC均退步；完整9位plan-tag Q组退步528.090ps。raw收益没有转为同flow物理收益，此点在31/32的组合效果必须独立测量。

重命名raw capacity两文件点将纯资源容量与原alloc_ready许可分开；Backend只替换容量查询，
ROB的共同birth仍阻止reset/restore/undo/kill，原Generic许可和动态旧birth参考保留。
共同birth SAT、严格86源lint（11.821s）、9项rename/Backend/恢复定向（113.889s）及独立接口复核PASS，
0新增FF/沿/容量；同闭包raw已完成：global−2.357577324→−2.237375259ns，改善120.202065ps，面积仅增加2.24µm²，69,606 DFF／716 ICG不变。最差路径移至resolve→commit/effect_allow→LSU prepared_tag，仍为负值。该变换未提前写RAT或空ROB metadata。

ICache8bank局部完整修复最终global/hold均不变（−.725467443/−.036415558ns），面积增加3440.36µm²；
保留为填充子路径取舍，不凭raw466.766ps收益推广。LSU response52修复global仅改善25.113ps，
面积增加2498.16µm²，late token→新prefix capture退步320.931ps，也没有直接整合。
新的固定journal RAS与固定LSQ行prefix分别针对上述实测长链；仍是私有候选，不属于已测的冻结30。

FP Join零填充简化的匹配6GiB fresh raw完成：全局setup/hold和其余组不变，全部18位FPR地址D改善127.502ps，面积减少20.16µm²，FF/ICG不变。初次4GiB export异常未产生STA，失败记录保留。该点供下一联合验证，不单独重复physical，尚未进入冻结30/默认。


### 联合31与后续解析级

31由完整30的86源组合4项零新增状态/沿改写：Rename容量分离、ROB plan-owner行读、FP Join零填充、RAS固定journal；7改文件。严格lint、136模块及继承矩阵、352软件、8定向、7理想ROI和两个完整基准均通过；CoreMark/Dhrystone的退休、周期、双退休、trap、AXI读写六项计数与30全部精确相同。同源整核1ns raw及真实单元／hold修复已完成：最终setup−1.882808447ns、hold+.005088600ns、面积3,605,016.80µm²，仍未通过1GHz。独立单点收益不相加，尚未替换默认28。

RAS固定journal的匹配物理结果为global−.725467443→−.710956454ns、area1072794.24→1071008.96µm²、96,568 DFF／1,065 ICG不变、连接图等价通过；result-head目标改善441.715ps，而token-head→RAS pointer退步175.805ps成为新全局，1ns仍未通过。LSQ固定行prefix的局部修复global−.715259254ns，相对原30仅改善23.354ps却增加4913.44µm²，不进入31。

分支解析事件级的独立验证与matched raw已完成，未混入31，后续整合到32／32a。真实Backend已验证连续解析、NPC最快写回同沿、捕获沿older retirement、older覆盖younger及在途fullflush丢弃；System8定向和7理想热区通过。两个完整基准均已通过：CoreMark周期相对30增加42296／.41864%，退休增加114且时间输出跨4/5位数字，尚未逐指令归因该退休差；Dhrystone仅增加138拍／.000827%。匹配完整闭包raw已完成：setup−2.357577324→−2.127763748ns（改善229.814ps）、面积+3608.36µm²、实际DFF+180／ICG不变。新事件180个D端最差−1.203368ns，1GHz仍FAIL，未单独跑physical。

原resident AGU在严格父28（RAW_SERIAL_QUERY=0）闭包的成对物理结果已收齐：global改善33.449ps，但面积增加2481.64µm²；head经adder改善307.914ps，完整head／RR到地址组却退步112.421ps。该旧闭包仅说明算术切分取舍，不替代30或31整核量测。


### 实际解析流水联合32

联合31全部CPU回归、双benchmark与整核1ns布局前PPA均完成。32继承完整31，仅Backend/Rob/CoreTop三文件加入180逻辑bit的真实解析事件级，86源、139主用例及全部矩阵已通过（1398.632s）；严格lint、新System构建（256.936s）、8定向和7理想ROI通过，原32完整软件最终351/352，PLIC仿真断言失败保留；修正后的32a完整软件与双基准全部通过。事件／II1／在途reset／全部16代分支恢复／连续older redirect均纳入139项。

32的publication owner在新模式为event resolve_tag Q，legacy为经过完整tag相等保护的plan Q；capture则在candidate完整tag==plan前件内从plan Q查询行，NOW/pending/generation全保留。根和CPU架构只读复核实际合并三源未发现新归属反例；该复核不替代完整仿真/PPA。独立解析级两benchmark均通过，CoreMark周期+.41864%，Dhrystone仅+138拍／.000827%；其单点raw和全部端点组已完成，尚无该单点physical结果。

独立System观察层已取得冻结30 CoreMark周期分布，六项实际计数与未插桩运行完全相同。10,103,258观测拍中，load/store队首未完成等待分别2,693,063／2,102,287拍；Dcache REFILL仅4243拍。Dcache IDLE为9,057,274拍，但该状态仍可处理命中读，不能把它解释为缓存空闲率。1,216,518个memory队首等待周期没有live LSQ行，需沿已转交的完成队列/写回归属解释，不能当作协议错误。观察层不进入综合。

后续RAS pair并行状态候选已拒绝：虽0FF／0沿、pointer改善263.270ps、面积减少321.16µm²，预测PC却退步193.018ps（countQ→PC退步242.031ps）；没有继续physical或加入31/32。fixed-journal父保留。

冻结30的双基准观察层已完整结束，并与未插桩执行的六项计数逐项相同。Dhrystone的16,695,032观测拍中，store队首未完成等待9,581,558拍，load等待2,357,830拍；Dcache REFILL仅2425拍。无live LSQ行的memory队首等待为1,802,950拍，包含RAW／CQ／WB正常归属转交，不能全部归因为冷源grant延迟。后续私有存储接纳与CQ完成通知改写分别验证真实AXI终端及真实九源WB的周期收益，再用完整程序和时序判断；具体观察分布见 tmp/rv64-cpi-profile30/REPORT.md。

### 32的PLIC断言边界与32a

32完整软件为351/352：AM plic-manual原断言在 raw_pending=1、event_valid=0、cleanup_pending=0、resident exception=1、rob_valid=00、birth=00 时失败。它把“尚未发布redirect的暂停退休周期”误判成正常退休周期。原失败未改写，32不启动后续PPA。

32a只修改CoreTop的R64_ASSERT分支，完整暂停条件加入raw/event pending和registered cleanup；保留正常周期raw异常与canonical异常等价及canonical不能丢证书，并检查暂停期间零退休、带异常暂停期间零birth。可综合预处理除空白行外逐字节一致，85份其他源不变。真实PLIC重放已PASS并直接记录上述失败拍事实；实际断言文本另通过64个合法组合及4类非法输入反例（丢证书、伪证书、暂停退休泄漏、暂停birth泄漏）。完整139及原矩阵／352软件／8定向／7理想／双基准重新执行后全部通过，未以单个PLIC通过替代全回归。32a整核raw已完成，后续单元优化按用户暂停指示未执行。

独立事件certificate研究点继承32a，在固定单沿消费event中验证归属从capture到publication不换代的条件，保留完整canonical权限和NPC接纳shadow，0新增FF/沿。12相关模块、352软件、8定向、7理想窗口及双基准均通过，双基准六项计数与32a完全相同。真实Backend／FP／Commit／20LSU匹配raw全局setup由−2.161410570改善至−1.831691742ns，hold仍−.036660694ns，面积增加4823.84µm²，仍未通过1GHz；retiredNPC与FP地址端点分别退步37.630ps／16.365ps。该改动已整合进联合33，未单独执行physical或替换默认。
