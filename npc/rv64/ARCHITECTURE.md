# 承岳64架构入口

当前主线为 **ChengYue64（承岳64）v1.0.0**，版本真源是
[core-version.mk](core-version.mk)。主线 RTL 直接列在 [vsrc/filelist.mk](vsrc/filelist.mk)，
按功能保存在 `vsrc/` 的各子目录；模块连接和参数以源码为准。

## 2026-10-13 Memory 续轮（当前）

当前默认为 **T1 + M-R**：保留两路 load 公告全包 Q，另将 DCache refill 维护写的容量查询
改为本次 R owner/beat 自身 key 的旧 FIFO Q。原 B/R 仲裁、字节更新、error/poison 排空及副作用边界
保持完整；未增加固定 hit 流水拍。详见[本批多轮实测报告](design/arch/memory-implementation-evaluation-20261013.md)。

系统 10/10、七个双发射热窗与完整 CoreMark10/Dhrystone10000 通过，周期仍为
4,423,886 / 6,033,084，分别与 T1 完全相同。同约束 clock-buffer setup 改善
0.263203859 ns，达到 −2.285944939 ns；flat area 为 2,416,852.780301 µm²。

在同一 M-R 映射上，逐端点真实延迟修复使完整负 hold 数为 0，最终 hold 为 +0.000625146 ns，
pulse/period 为 +0.549876153 / +0.408300072 ns；setup 保持 −2.285944939 ns，
修复后 flat area 为 2,423,057.580301 µm²。这是附加的网表物理实验结果，非 RTL 新流水级。
500 MHz / 2 ns 总判定仍 FAIL；hold 仅约 0.625 ps 余量，仍限于 TT 1.2 V / 25°C
布局前模型，没有合格 Fmax、布局后时序或实测功耗结论。

后续 M-R+M-S 单独关闭普通 read empty-flow。完整 CoreMark / Dhrystone 周期增加
5.44458% / 7.13066%；系统与局部验证通过。同约束 clock-buffer setup 为 −1.966506362 ns，
比 M-R 再改善 0.319438577 ns，仍未通过 500 MHz；flat area 为 2,416,641.660301 µm²。
独立架构评估据此维持 M-R 为生产默认，M-S 保留为已测取舍候选。
该参数变化未合入生产；本批没有补偿其周期代价的已实现设计。
普通 read 入 Service Q 的早期 kill 已有直接驻留、恰一次接受、无 WB 排空观测；
prepared 当前控制继续保留，且已成为新 worst 的 Service 中段；后续取舍应针对该实测边界。
M-R 的额外 hold 修复结果不能代入 M-S。

## 2026-10-13 T1/T2 实现评估（前批历史）

当前实验目标为 55 nm ICS55 + ECOS SRAM、TT 1.2 V / 25°C、500 MHz / 2 ns，
保留原 0.05 ns uncertainty。ICache 使用 2 个真实 256×128 SRAM 宏，
DCache 使用 4 个真实 256×64 掩码 SRAM 宏；寄存状态信用与数据保护边界已合入。
[上一批保护边界](design/arch/memory-protection-boundary-20261012.md)对应已测基线 e44dac90b。

当批默认采用 **T1：两路最终 load 公告全包 Q**，在 current owner 认证前整体登记 valid/full-tag/data，
共 148 bit，无完成 owner/ready/ack；规范 CQ/WB 与 WB/history/PRF 回退合同保持。
实际 mapped 已确认整包 FF 及 raw notice→IQ/RR 目标断链。
完整 CoreMark10 / Dhrystone10000 为 4,423,886 / 6,033,084 cycles，
相对上一已测基线增加 4.7363% / 4.1605%；系统 10 场景与 7 个 CPI=0.5 双发射热窗口通过。

同口径 clock-buffer STA 的 setup / hold 为 −2.549148798 / −0.313464463 ns，
pulse / period 为 +0.549876153 / +0.408300072 ns，最终 flat 映射面积 2,415,687.980301 µm²。
setup 较基线改善 0.677219629 ns，但 **500 MHz 仍 FAIL**；新 worst 已转到保护/访存选择、
跨 bank ready 至 DCache overlay 数据快照。当批仍是 pre-layout ideal-clock 口径，无合格 Fmax 或实测功耗结论。

第二轮 **T1+T2-min** 实际关闭三个 RR direct 选项，复用每 lane 1 ingress + 2 terminal，
已验证 IQ current source→operand/shift 的第二段断链。完整程序为 4,616,448 / 6,418,541 cycles，
相对 T1 再增加 4.3528% / 6.3891%；全局四项 slack 与 T1 相同，面积 2,399,191.500301 µm²。
因此 T2 留作可复用实验点，**当批默认三个 RR direct 选项仍开启**；未扩两 capsule，
T3/P1/P2/P3 仍属条件候选，没有借本轮文档变成现有实现。

- [本批实现、完整测量、保留裁决与清理](design/arch/timing-implementation-evaluation-20261013.md)
- [时序导向多轮设计](design/arch/timing-architecture-rounds-20261013.md)
- [性能导向多轮设计](design/arch/performance-architecture-rounds-20261013.md)
- [设计阶段独立评估与条件实验顺序](design/arch/parallel-architecture-review-20261013.md)

双路架构设计与新上下文独立评估已在本批产生合同纠错价值，有条件地纳入
[CPU Architect 路由](../../.github/instructions/cpu-architect-routing.instructions.md)；
架构 agent 仍不读 RTL，实现和取证由独立角色执行。没有单 agent 对照，不声称量化效率提升。
每轮在必要分析完成后只保留结果、关键诊断及小复现输入，
使用[清理入口](syn/README.md)；本批大网表和仿真编译产物均已清理。
下文更早测量只描述对应历史点，不能与本批当前 M-R 测量混用。

## 系统边界

| 层次 | 实现 | 职责 |
| --- | --- | --- |
| CPU | [R64CoreTop](vsrc/core/R64CoreTop.v) | 取指、双发射乱序后端、整数/浮点执行、提交/CSR、LSU/MMU/Cache、AXI |
| 系统 | [R64SystemTop](vsrc/platform/R64SystemTop.v) | CPU、AXI fabric、CLINT、PLIC、UART、RTC 和 syscon |
| 可选协处理器系统 | [R64TensorSystemTop](vsrc/platform/R64TensorSystemTop.v) | 真实 Tensor/NPU 接口、DMA 和缓存一致性配合 |
| 仿真宿主与观察 | [sim/](sim/README.md) | RTL 仿真封装输出观察状态；C++ 宿主驱动时钟、镜像和设备，不参与硬件综合 |
| 架构状态差分 | [difftest/](difftest/README.md) | NEMU 接口、退休/trap 对齐、PC/GPR/FPR 和选定 CSR 比较 |
| 定向测试与回归 | [testbench/chengyue64](testbench/chengyue64/README.md) | 模块激励、程序、oracle、测试生成器和回归调度 |

主线能力包括 RV64IMAFDC、Zicsr/Zifencei、Zba/Zbb/Zbc/Zbs、M/S/U、Sv39、
16 项 PMP、原子操作与 Sdtrig 地址触发器。扩展能力及系统接入取舍见
[系统替换记录](design/arch/rv64-replacement.md)；具体行为由 RTL、参考配置和定向测试共同约束。

## 详细设计

- [自治域公共协议](vsrc/PROTOCOLS.md)：团队职责、Fetch/Dispatch/MEM/FP/Serial记录，Recovery/Effect/Retire事件、取消与排空、独立开发入口。
- [全核拓扑](vsrc/TOPOLOGY.md)：请求、完成、信用、恢复和不可取消事务的连接。
- [模块清单](vsrc/MODULES.md)：源码中声明的模块与文件位置；它不是实例化证明。
- [前端](vsrc/frontend/TOPOLOGY.md)、[后端](vsrc/backend/TOPOLOGY.md)、
  [浮点](vsrc/fp/TOPOLOGY.md)、[提交控制](vsrc/control/TOPOLOGY.md)、
  [翻译与保护](vsrc/memory/TOPOLOGY.md)、[LSU/Cache](vsrc/lsu/TOPOLOGY.md)、
  [总线与平台](vsrc/bus/TOPOLOGY.md)：各模块域的详细连接与设计取舍。
- [设计资料分类](design/README.md)：主线说明、共享 IP 规范、文献和旧核资料的适用范围。

源码旁的拓扑文档记录状态 owner、寄存边界、容量/带宽、信用、取消与副作用。
2026-10-10 当前工作区进一步形成自治事务域：Execution拥有唯一busy scoreboard和IQ/PRF/RR，
TranslationService拥有opaque token账本，PhysicalMemory拥有cache路由，
Control生成携带head身份的Effect与已接受Retire；跨域Fetch/Dispatch及服务命令定义为公共ABI。
各域独立编译与mock测试入口见[公共协议](vsrc/PROTOCOLS.md)，新增结构及验证见[全核拓扑](vsrc/TOPOLOGY.md)。

当前协议 v2 在 RTL 中进一步引入真实时序边界：Recovery 在接收域登记，配合两拍 birth fence；
Memory Effect 使用完整 tag 的寄存租约，Memory Retire 与 reuse 公告由本域状态驱动；
LSQ 空槽按 rank 单向发布，Execution 本地核对提前供值身份；
物理响应在接受边沿捕获payload/live，下一边沿可进入完成队列；payload由已登记占用状态仲裁。
迟到分支只在 ROB 核对当前完整身份和预备恢复计划后成为架构事件。
这些边界改变了流水延迟，不能沿用较早阶段的逐周期相同结论。

2026-10-10 基线验证见[attempt3 汇总](build/rtl-domain-rebuild-20261010/attempt3/validation-summary.json)：
适用模块/配置/负向/独立域、352 项软件、CoreMark/Dhrystone、Core/System/IO/block 与 L2 all 全部通过，
真实标准单元综合通过；1 ns STA 仍失败。相对本轮前基线，寄存器间 WNS 改善约 0.425 ns、
面积增加约 0.986%，CoreMark/Dhrystone 周期增加约 6.51%/5.80%。
剩余同步 birth 控制路径、实际断链证据与完整测量见[当前全核拓扑](vsrc/TOPOLOGY.md)。
Tensor/NPU 与 L3 不在本轮范围内；该工作区结果不改变正式 release/PPA 状态。

2026-10-11 的 v7 基线增加执行域内部的ALU调度promise和RR晚到操作数状态，普通RAW执行间隔定向从3拍降为2拍。
访存保留Bare outcome直入、prepared store的无owner镜像准备、真实B后的退休重叠及响应入口去冗余等待。
LSQ新owner初始化转发掩码，避免取消预写后同槽store复用继承旧有效性。
bind到翻译队列继续经过canonical LSQ寄存状态；同拍热绑定实验因真实STA关键路径退化已撤下。
该 v7 基线保留关闭重复Execute当拍接受唤醒、RR独立捕获四路宽数值的修正。
RR将preg和已认证valid与数值共同登记，已有首次读阶段只匹配本地Q，删除当前IQ源到arrival状态的组合匹配。
RR到Execute分为已登记数值就绪和本地ALU就绪两条有效通道；共享MEM/MDU/FP/Serial仲裁与实际fire
只使用前者，ALU/分支可使用当前认证的驻留ALU值，消费确认仅在RR本地合并。
同源验证输出位于[双发射利用率优化](build/dual-utilization-20261011/alu-experiment/v7-validation/)；
本版完整功能验证已通过：CoreMark 8653974周期、Dhrystone 12745924周期、L2 12073761周期，
相对attempt3分别降低9.40%、15.56%、13.60%；同源标准单元综合通过，1ns STA仍失败。
全局setup WNS为-1.835898995ns，较起点改善0.04758ns；寄存器间WNS较起点退步0.02038ns，
setup TNS也退步，面积增加0.872%。精确断链及剩余LSU→Dcache关键路径见[当前全核拓扑](vsrc/TOPOLOGY.md)。

2026-10-12 零发射优化阶段在第十八批达到验收线：完整 CoreMark 10 迭代、Dhrystone
10000 的 IQ→RR 零发射占比均低于 50%、程序周期下降及适用全量功能和 L2 通过。
该阶段按用户要求暂缓综合与 STA。随后第二十批进入保持程序周期的 RTL 组合逻辑解耦，
重新进行了同约束综合与 STA，结果见下文；以上 v7 的功能与 PPA 结果仅描述历史基线。
Tensor/NPU、L3 继续不在范围内。

当前 RTL 保留跨域事务 owner、完整 tag、恢复收件、真实完成与精确副作用授权，
在已有空槽和固定候选路径上去除额外等待：RR 使用真实完整操作数直入和局部 ALU 数值旁路，
Memory 提供不承担完成所有权的最终 load 数值公告，普通前驱真实退休后可将寄存租约交给下一条 store，
AXI 写命令、Fabric AW 接收和 B 返回支持空槽直通。每条直通路径仍保留背压时的原始寄存存储；
错误、取消与背压不产生虚假的完成。逐项边界和参数见[公共协议](vsrc/PROTOCOLS.md)。
原始 IQ 发射计数保持不变，并独立观察实际 Execute、RR 等待和程序周期，防止只把等待迁入 RR。
第十八批完整 CoreMark 10 迭代为 4016641 周期，IQ→RR 零发射 44.4174%，
实际 Execute 零发射 42.9715%；Dhrystone 10000 次为 5691655 周期，IQ→RR
零发射 48.3838%，实际 Execute 零发射 47.5014%。原程序检查、CoreMark CRC 与真实
DiffTest 均通过，相对 v7 周期分别下降 53.59% 和 55.35%。两项完整原 IQ→RR 指标
已经同时低于阶段线；适用全量功能与 L2 均通过，运行期间冻结源码未变化，本阶段验收完成。
完整逐批测量见[完整程序进展](build/zero-issue-20261011/full-program-progress.json)。

冻结第十六批的适用全量功能验证已完成：201 项默认模块、53 项配置、17 项负向场景、
10 项独立域动态、8 项独立域严格 lint、sum_equal、352 项软件及 Core/System/IO/block
全部通过，Core/System/Platform 严格 lint 通过。L2 all 完成 17 个阶段，6063076 条提交、
7296707 周期、486 次 trap，并自然触发一次关机。范围与来源见
[第十六批验证](build/zero-issue-20261011/batch16-validation/validation-summary.json)。
这一冻结源包含错误 source PINNED 修复与双退休 lease，不包含后述隔离写回、分支预测实验；
运行期间冻结源码未变化。

第十五批完整 CoreMark/Dhrystone 分别为 4699249/6753673 周期、
IQ 零发射 51.6148%/56.7211%，其适用全量与 L2 也已通过；
冻结第十五批未包含随后加入的 PINNED 和双退休 lease。
[第十五批汇总](build/zero-issue-20261011/batch15-validation/validation-summary.json)和
[第十四批汇总](build/zero-issue-20261011/batch14-validation/validation-summary.json)
继续保存对应版本的独立结果。

第十五批在空 matcher lane 上复用原逐字节 store 选择网络，允许成功普通整数 load
翻译响应直接捕获原 query Q，保留精确 winner pin、取消与实际错误 source 检查。
同时修正 CoreTop 仿真断言的观察时点：真实接受的窄 store 错误完成可先于 ROB resident
证书投影到 Commit，断言须计入这一实际接受；生产 head-exception birth stop 仍由原寄存状态驱动。
该断言修改在未定义 R64_ASSERT 时预处理等价。干净候选 22 项动态、5 项 strict lint 通过，
冻结第十五批完整回归已通过，结果位于
[第十五批验证](build/zero-issue-20261011/batch15-validation/validation-summary.json)。
head-bound load promise / fixed-current-value 候选尚未合入，其短程序收益不足以支持保留。
后续本地正确性修复在错误 store 仍被 descriptor/query 引用时保留 PINNED 源槽，
错误 completion 与精确 trap 时点保持不变；它已通过独立接口与真实 Core 回归，
当前工作区包含该修复，冻结第十五批完整性能/功能结果不包含它。

第十六批增加 DUAL_RETIRE_STORE_LEASE：ROB 只发布第三个驻留 owner 的 valid 和完整 tag，
Control 仅在真实双退休、两条前驱均为普通非异常指令且原副作用许可有效时，
把该第三条未完成 store 安装为下一拍 lease。Memory 仍只消费寄存许可；同沿完成、错误、
恢复、Trace 背压和同沿新 birth 都不能凭候选产生年轻物理副作用。
这一改动与上述 PINNED 修复共同构成当前第十六批，详细合同见[公共协议](vsrc/PROTOCOLS.md)。

第十六批的自然终止短诊断为：CoreMark 1 迭代 535106 周期、
IQ 零发射 53.0980%、实际 Execute 零发射 51.6054%；Dhrystone 1000 次 676626 周期、
IQ 零发射 56.4290%、实际 Execute 零发射 55.3365%，均通过真实 DiffTest。
相对第十五批短诊断，CoreMark 周期仅减少 141、IQ 零发射占比略升；
Dhrystone 周期减少 19722、IQ 与 Execute 零发射占比均下降。
N3 的 30 项相关动态配置、10 项独立域动态、10 项参数/Core 严格 lint 和 8 项域 lint 已通过；
源槽修复与响应转发、真实 Core 错误恢复的 3 项整合测试已通过。
这些定向和短程序结果用于说明变化来源；上文的冻结第十六批完整程序、适用全量功能与 L2
结果提供更完整的验证，但 IQ 零发射仍未达阶段目标。
证据边界见[第十六批状态](build/zero-issue-20261011/batch16-status.json)和
[短诊断进展](build/zero-issue-20261011/diagnostic-progress.json)。

第十六批之后的隔离 ALU 写回请求实验暂未合入：提前 token 请求使两个短程序周期都略增；
下一拍实际占用请求使 CoreMark 减少 1284 周期、Dhrystone 增加 1987 周期。
尽管写回等待计数大幅减少，仍没有稳定的程序收益，不能按等待计数或 IQ 零占比单项推广；
完整 A/B 数据保存在[写回请求比较](build/zero-issue-20261011/alu-writeback-preview-comparison.json)。

被动分支观察按实际 ROB birth 序号、完整 tag、resolve 与 retire/kill 关联。
短 Dhrystone 中，一处真实退休方向全 T 的分支受到同 PC、随后取消的 N 训练影响；
另外两个热点分别呈现固定的 30 次和 19 次 T 后 N，另有 NT 交替热点。
CoreMark 则确认了一组不同 PC 共用方向表项、方向相反的冲突。
这些观察支持分别实验退休方向训练、表项容量与循环/历史预测；
它们尚未成为主线功能或性能结论。生命周期与具体见证见
[分支分析](build/zero-issue-20261011/alu-writeback-next-preview-probe/branch-analysis/comparison.json)。

第十七批合入普通整数访存 bind 的翻译空路径与 store 热绑定，并把方向表配置为
1024 项、首次有效训练使用强状态。原始 IQ/Execute 计数保持不变。可选退休方向训练已完成
接口与联合测试，但组合 A/B 中关闭时两个程序都略快，Core 默认保持 resolve 训练。
具体生命周期见[公共协议](vsrc/PROTOCOLS.md)。

同源自然短诊断 CoreMark 1 迭代为 494215 周期、IQ 零发射 50.4882%、实际 Execute
49.1447%；Dhrystone 1000 次为 645583 周期、IQ 零发射 53.2614%、实际 Execute
52.2188%，提交数分别保持 353063/435533，原程序检查与真实 DiffTest 全部通过。
相比第十六批短程序，周期分别减少 40891/31043。新增 8 项联合测试以及预测参数矩阵、
翻译服务与严格检查通过。第十七批完整 CoreMark 10 为 4332109 周期，IQ 零发射
48.8919%、实际 Execute 47.4991%；完整 Dhrystone 10000 为 6257374 周期，
IQ 零发射 52.8907%、实际 Execute 51.8481%，均通过原程序检查和真实 DiffTest。
相对 v7 周期下降 49.94%/50.91%，但 Dhrystone 仍未达到阶段线。209 项适用默认模块
（原全量201项加遗漏8项补测）、其余配置/负向/域检查和352项软件均通过；L2 all
完成17阶段，6972462周期、6063076条提交、486次trap及一次自然关机。完整范围见
[第十七批验证](build/zero-issue-20261011/batch17-validation/validation-summary.json)。
A/B 和前端原因分解见[组合候选比较](build/zero-issue-20261011/throughput-combined-preview-probe/frontend-comparison.json)。
第十八批进一步合入批量后缀回滚与 128 项早期块目标表。
ROB 仍在原边沿发布取消，下一沿把登记的后缀集合统一应用到 Rename 和 Scoreboard；
更老的真实恢复会合并集合并延期整批应用，原 Inbox、birth fence 与复用阻塞保持。
FTB 只扩大索引并同步 repair 来源字段，仍使用原 PC[24:4] 签名和 68 位预测计划；
未实施多目标槽、循环预测、not-taken 保留或其他新的训练策略。

联合自然短诊断 CoreMark 1 迭代为 459690 周期、IQ 零发射 46.3714%、
实际 Execute 44.9978%；Dhrystone 1000 次为 588357 周期、IQ 零发射 48.8852%、
实际 Execute 47.9973%。提交数保持 353063/435533，原程序检查、真实 DiffTest 和
原计数守恒均通过。相对第十七批短程序分别减少 34525/57226 周期。
单独恢复与容量 A/B 及联合结果见[恢复与前端比较](build/zero-issue-20261011/recovery-ftb-preview-comparison.json)。

批量恢复的独立逆序 birth ledger、实际 Backend、旧回归与严格检查通过；
FTB 的 5/7/8 位索引定向、原 32 项逐拍对照及严格检查通过，联合 Core/System strict 通过。
第十八批默认适用模块库存为 213 项（另有用户排除的 Tensor 测试）。
第十八批完整 CoreMark 10 / Dhrystone 10000 已分别达到 44.4174% / 48.3838% 原 IQ 零发射，
原程序与真实 DiffTest 通过。适用默认模块213项、配置53项、负向17项、独立域动态10项、
域严格 lint 8项、sum_equal、352项软件及 Core/System/IO/block 全部通过，
Core/System/Platform 严格 lint 通过。L2 all 完成17阶段，6757074周期、6063076条提交、
486次trap与一次自然关机；运行期间冻结源码未变化。

原全量脚本漏读 TESTS += 的12项已用同一冻结源补测；方向流水与乘法器各发生一次宿主
超时，已保留失败并完成单项复验。方向流水统一原定向入口的120秒预算，乘法器仍按原60秒
通过；RTL、TB、断言和功能 oracle 均未改动。原批次 runner 的非零返回码保留，
最终适用默认覆盖按原200项、补测12项及乘法独立复验1项合计213项，完整范围见
[第十八批验证](build/zero-issue-20261011/batch18-validation/validation-summary.json)。
第十八批零发射阶段目标已达成；当时未测量综合与 STA，该批功能结果本身不构成时序或 PPA 结论。


第二十批在保持第十八批流水与事务语义的前提下，拆除了跨模块的非必要组合依赖：
Rename 批量回滚改用固定行解码和平衡优先树，LSU 请求队列发布本地 raw occupancy；
AXI 的旧 B 资格只引用驻留 AW/W 状态，Dcache 的直接 store 资格独立于 load overlap ready；
ROB 向 Commit 提供当前驻留 head 的 Serial 退休资格，与原完整 tag 配对，再由 Commit
施加原恢复、事件和 Trace 接受条件。普通 store 仍等待真实完成，Serial 副作用的退休边沿不变。
本批未增加寄存级、气泡、时钟例外或黑盒，协议及理由见[公共协议](vsrc/PROTOCOLS.md)。

真实标准单元综合与 STA 使用同一 R64CoreTop、icsprout55 TT 1.2 V / 25°C、1 ns 时钟、
ABC 600 ps 和最大扇出 8；面积统一取最终 STA 导出网表。第十九批局部改写虽略减面积，
全局 WNS 却退步，因此继续依据真实跨模块关键路径形成第二十批。

| 同约束测量 | 第十八批重测 | 第十九批局部改写 | 第二十批当前 |
| --- | ---: | ---: | ---: |
| 最终映射面积（µm²） | 3423034.16 | 3412286.64 | 3406233.04 |
| setup WNS（ns） | -7.170516014 | -7.210239887 | -4.147320747 |
| setup TNS（ns） | -282840.625000 | -285247.437500 | -178187.671875 |
| hold WNS（ns） | -0.036660694 | -0.036660694 | -0.036660694 |
| hold TNS（ns） | -5.241828 | -5.223722 | -5.223722 |

相对同源第十八批重测，第二十批 setup WNS 改善 3.023195 ns，
面积变化 -0.4908%。当前最长路径为 PMP config[19] → 保护 fault → LSU mem_size / split → MemoryService cache 地址 → Dcache 旧 store set 排除与 tag 读选择 → tagrd0_q[1][3]；数据到达为 5.060575008 ns，不再跨 AXI B、ROB、Serial 和前端。真实 mapped fanin 检查也确认新写命令／数据到旧 B，以及 store_done／公共 retire 到 serial_commit／ICache invalidate 的指定依赖均已消失；Serial 到 invalidate 的正向对照仍存在。
标准单元映射通过，1 ns STA 的原始结论仍为 FAIL；以上是布局前同约束比较，
不宣称物理签核、正式 PPA promotion 或 release 更新。完整数值与原报告见
[时序比较](build/timing-preserve-20261012/timing-comparison.json)。

第二十批完整 CoreMark 10 和 Dhrystone 10000 分别保持 4016641 / 5691655 周期，
IQ 零发射占比保持 44.4174% / 48.3838%，实际 Execute 保持 42.9715% / 47.5014%。
提交数、性能计数器以及合计 314 行原始性能报告与第十八批逐字节一致；原程序检查、CRC
与真实 DiffTest 均通过。这说明已测完整工作负载的行为与性能保持，不等同于全状态逐拍形式证明。

[第二十批完整功能验证](build/zero-issue-20261011/batch20-validation/validation-summary.json)
自然通过原有适用默认模块 213 项、配置 53 项、负向 17 项、独立域动态 10 项、
域严格 lint 8 项、sum_equal、352 项软件及 Core/System/IO/block；无补测、重试或预算变更。
L2 all 仍为 17 阶段、6757074 周期、6063076 条提交、486 次 trap 与一次自然关机，
比较字段全部与第十八批一致，冻结源码运行期间未变化。
新增 Serial candidate 回归在相同生产 RTL 上独立通过 HEAD_CLASS=0/1 两配置，
交付默认适用库存因此为 214 项；此项是对上述 213 项完整验证的补充，
不是原冻结 runner 执行了 214 项。见[行为比较](build/timing-preserve-20261012/batch20-behavior-comparison.json)
和[新入口验证](build/timing-preserve-20261012/test-entry-check/result.json)。

AXI/Dcache/队列的旧新动态对照、事务边界定向与 Serial 许可断言通过；
Rename 已有完整模块动态对照及部分配置组合证明，但默认 32 行 BATCH=1 的符号证明
因超时未完成，另一次固定 head 的先验受资源上限中止，均为 INCONCLUSIVE，
不作为 formal PASS。相关状态见[Rename 固定 head 先验](build/timing-preserve-20261012/rename-head-case-proof/summary.json)。


同日较早的控制链解耦阶段：ROB退休候选与Commit前缀接受分离，
LSU完成改为固定payload槽，AXI读请求采用两描述符Q信用。恢复、原子birth、完整tag授权
和已接受外部事务排空保持明确联系；范围与验证见[全核控制链解耦](vsrc/TOPOLOGY.md)。
2026-10-09 全核职责重审后，Control 内聚精确退休/CSR协议，Frontend.access 管理取指访问，
当时的LSU.translation_owners 保存已接受翻译的返回归属（当前已迁入TranslationService），FP 入口收窄为command32；
详见[全核职责重构](vsrc/TOPOLOGY.md)。该阶段保持原流水和事务语义，其验证范围独立于历史 PPA 测量。
2026-10-09 已按当前 RTL 统一整理[全核连接](vsrc/TOPOLOGY.md)与前端、后端、浮点、提交控制、
翻译/保护、LSU/Cache、BUS/平台各域说明。每域从生产配置、文件职责与真实实例进入，再说明接收边沿、
状态 owner、信用、取消和副作用；[RTL 目录导航](vsrc/README.md)提供对应入口，
[平台说明](vsrc/platform/README.md)另列默认系统与可选 Tensor/GMEM 接入。
[网页设计交接约定](ai/topology-contract.md)说明如何据此表达跨单元候选，当前图与未实施的候选图分别保存。
拓扑文档也包含标有日期的优化测量；这些测量只描述对应版本。
最新正式版本的 CPI/STA 和验证范围在[发布说明](releases/chengyue64-v1.0.0/README.md)中维护。

2026-10-08 的[第三轮网页架构实验](ai/tests/2026-10-08-round3-cq-value/RESULT.md)完成了 CQ 确值早唤醒/供值与同拍取消发布联合实现。
两个完整基准周期下降 3.47%/2.32%，但全局 setup WNS 未满足该轮改善要求，联合候选已归档，工作树恢复第一轮保留基线 B。
2026-10-10 的控制解耦从 B 继续修改；R3 的补丁和测量仍是候选历史，未更新正式发布版本或将 R3 成绩作为当前成绩。

## 验证和实现证据

[DiffTest 文档](difftest/README.md)说明逐条提交的 PC/GPR/FPR 检查，
以及当拍提交和 trap 处理后的 CSR 比较；[系统仿真](sim/README.md)
说明 Linux、设备与 NPU 的运行边界。[综合与 STA](syn/README.md)说明真实网表、约束和时序判定。
理想吞吐目标为 CPI 0.5，当前 2 ns / 500 MHz 时序尚未闭合；局部测试、短程序和布局前报告
不能代替完整系统验证或物理签核。

## 历史资料

冻结 timing28–33、早期 CPU-only 暂停范围及旧 Ooo* 核的架构快照已归入
[历史文档](design/history/README.md)。其任务状态和测量不描述当前主线。
旧核完整源码、配置与文档见[封存包](../pack/rv64core-legacy-20260916/README.md)。
旧 Ooo* 主核不在 `vsrc/` 中；个别测试复用的旧实现位于测试 oracle 目录，保持其验证用途。
