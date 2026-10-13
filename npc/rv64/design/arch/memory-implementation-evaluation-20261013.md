# Memory 多轮实现与测量（2026-10-13）

本轮从 T1 开始。共同条件为 ICS55 H7CL + 两种 ECOS SRAM Liberty，TT 1.2 V / 25°C，
500 MHz / 2 ns，0.05 ns uncertainty，以及原输入/输出约束。面积记录为实际 flat mapped cell area，
包括宏，不代表布局后核心面积；功耗未测。所有 timing FAIL 原样保留，不由 WNS 换算合格 Fmax。

最终选择：**T1 + M-R 作为生产默认；M-R + M-S 留作已测量候选**。本批完成两轮 RTL
实验和六轮 hold 修复，M-R 的完整程序周期不变、setup 改善；M-S 有进一步时序收益和明确
周期代价。两者均未满足 500 MHz。默认选择不以面积为主因。

## 已完成：M-R

M-R 只将 DCache refill 的维护 FIFO 容量查询改为当前 R owner/beat 自身键的旧 Q 查询。
占用 head 拒绝合并；tail 可合并；无匹配时仅用旧空槽，不借同沿 drain。
真实 B fire 优先级、每 bank 单写入口、原 allocate/error/poison 字节写入、安装资格和 owner 排空不变。
本轮不增加 FIFO、owner、SRAM 端口或固定 hit 流水拍。RTL 注释明确用于 ECOS55 工艺适配。

| 同口径测量 | T1 父点 | M-R | M-R + ICache D hold 修复 |
| --- | ---: | ---: | ---: |
| CoreMark10 cycles / commits | 4,423,886 / 3,218,537 | 4,423,886 / 3,218,537 | 同一 M-R RTL |
| Dhrystone10000 cycles / commits | 6,033,084 / 4,260,629 | 6,033,084 / 4,260,629 | 同一 M-R RTL |
| buffered setup slack / ns | -2.549148798 | -2.285944939 | -2.285944939 |
| hold slack / ns | -0.313464463 | -0.313464463 | -0.162068039 |
| min pulse slack / ns | +0.549876153 | +0.549876153 | +0.549876153 |
| min period slack / ns | +0.408300072 | +0.408300072 | +0.408300072 |
| flat cell area / µm² | 2,415,687.980301 | 2,416,852.780301 | 2,419,003.180301 |
| 原 500 MHz 四项判定 | FAIL | FAIL | FAIL |

M-R 完整 benchmark 的 cycles、commits 及可取得的 counters 与 T1 相同，两个 CPI 为
1.3745021418 / 1.4160078242。相对更早的 e44/c7 基线，累计 cycles 仍增加
4.73634% / 4.16049%；本轮没有消除 T1 的历史周期代价。
M-R setup 改善 0.263203859 ns，buffered 面积增加 1,164.8 µm²，约 0.04822%。

真实 raw flat 面积为 2,404,485.180301 µm²，raw min-pulse 为 -20.870256424 ns。
时钟负载处理实际增加 6,310 个 BUFX4H7L，面积 +12,367.6 µm²；原 ICG/宏时钟检查仍执行。
每个映射点均保留 2 个 ICache 256×128 与 4 个 DCache 256×64 ECOS SRAM。

同源系统 10/10、七个双发射热窗（各 768 指令 / 384 周期）、完整 NEMU DiffTest benchmarks 通过。
leaf cycle/vendor 逐字节 oracle、错误 B-key mutation、真实 DCache/Service 和 strict lint 均有实际结果。
补充错误 refill 与 invalidate/poison 用例检查接受 beat、真实维护写及全部 SRAM word。
poison-Q 与无信用同拍计数仍为 0，不能把相邻事件覆盖说成这一精确交叉已发生。

实际 mapped 核查找到 9 个 R-key 动态标量和每 bank 21 个 FIFO 状态 FF，容量许可均有真实 RREADY 消费。
指定 lookup/read 授权到 R credit/RREADY 无组合可达。首版因 flatten alias 缺失报告 GAP，修正实际别名后
v2 缺口为 0；未改 RTL。该图止于 FF/ICG/SRAM，不证明可敏化性或 formal 等价。
overlay 的正常 read 捕获还涉及 ICG enable，不能仅凭 D-pin 图零可达宣称所有控制已消失。

新 worst 转为 Service 当前 read-offer 地址选择，经 DCache direct-store 共享控制与 AXI first-W
信用回到 Cache 状态 Q。局部 read/store 资格互斥不能升级为 false path，也不代表普通 load 实际发写。
这为下一单变量 M-S 提供依据。

## 已完成：第一个宏 hold 子轮

在已完成 clock parent 上，仅对实际负 hold 的 ICache D[k] sink 分支各加 3 个真实
DLY4X2H7L，共 256 端点 / 768 单元，+2,150.4 µm²。收缩新增非反相链后核对所有原 cell/pin，
mapped check/stat 通过，原完整 STA 执行完成并保留 FAIL；setup 不变，256 个 ICache D 负检查消除。

完整报告仍有 DCache D/WEB/GWEB/CEB、ICache A、标准 FF D 与 ICG E 负 hold，
最差变为 DCache D 的 -0.162068039 ns。该子轮整体仍 TIMING_FAIL。
没有修改 clock、reset、SDC 或宏时序弧。后续只根据真实剩余端点继续实验。

## 后续宏与输入 hold 子轮

下表每行都是实际完成的独立 netlist/STA 结果。所有行继续使用原 SDC、真实三份 Liberty
以及完整 setup/hold/pulse/period 检查；宏延迟从同一个 M-R clock parent 重建，输入子轮明确承接
对应宏子轮。数值来自各子轮完成 JSON，表中每项整体仍因 setup 为负而 FAIL。

| 映射子轮 | setup / ns | hold / ns | 负 hold 数 | flat area / µm² |
| --- | ---: | ---: | ---: | ---: |
| 仅 ICache D 三段 | -2.285944939 | -0.162068039 | 680 | 2,419,003.180301 |
| 所有已报告宏 pin 三段 | -2.441397429 | -0.036660694 | 144 | 2,423,505.580301 |
| D 三段，其余宏 pin 一段 | -2.285944939 | -0.036660694 | 400 | 2,421,937.580301 |
| 上一行 + 144 个输入短路径 | -2.285944939 | -0.005049461 | 256 | 2,422,340.780301 |
| D 三段、WEB 两段，其余宏 pin 一段 | -2.285944939 | -0.036660694 | 144 | 2,422,654.380301 |
| 上一行 + 144 个输入短路径（保留物理方法） | -2.285944939 | 0.000625146 | 0 | 2,423,057.580301 |

全部三段消除宏 hold，却把 CEB setup 推坏，因此不保留。控制 pin 改一段后 setup 恢复，
但完整报告仍有 256 个 WEB 约 -0.005049 ns 的违例；不能仅凭“全局 worst 已转到标准 FF”
宣称所有宏通过。仅增加 WEB 的级数后，宏负 hold 清零，再修复实际 142 个标准 FF D 和
2 个 ICG E 输入短路径，完整负 hold 报告为空。

最终相对 M-R clock parent 增加 2,216 个 DLY4X2H7L、6,204.8 µm²；相对 T1 clock parent
累计增加 7,369.6 µm²。setup 仍 -2.285944939 ns，hold +0.000625146 ns，
pulse/period 仍 +0.549876153 / +0.408300072 ns。
hold 余量约 0.625 ps，仅说明本次 TT 25°C、无布线寄生模型的检查转正，500 MHz 总判定仍 FAIL。

工具只对实际负 hold 的显式 ECOS 数据/地址/写掩码/控制输入支路增加非反相工艺延迟，
不改 clock 输入、宏模型或约束；标准输入与门控使能使用既有独立工具。每次修改后均执行原 pin
收缩等价、actual mapped check/stat 和完整 STA。工具相关 49 项测试通过。
这些是网表物理修复实验，不是在 RTL 中加入额外流水拍，功能周期沿用同一 M-R RTL 结果。

## 已完成：M-S

M-S 从冻结 M-R 出发，仅关闭已有普通 read empty-flow；prepared 保留。
局部与系统 10/10、七个双发射热窗、完整 benchmarks 已完成且同源：
CoreMark10 为 4,664,748 cycles / 3,218,537 commits，CPI 1.4493380067，
比 M-R 增加 5.44458%；Dhrystone10000 为 6,463,283 / 4,260,629，CPI 1.5169785964，
比 M-R 增加 7.13066%。commits 与父点完全相同；相对更早 e44/c7 基线，周期累计
增加 10.43879% / 11.58783%。

| 同口径测量 | M-R | M-R + M-S |
| --- | ---: | ---: |
| raw flat area / µm² | 2,404,485.180301 | 2,404,274.060301 |
| clock-buffer flat area / µm² | 2,416,852.780301 | 2,416,641.660301 |
| buffered setup / ns | -2.285944939 | -1.966506362 |
| hold / ns | -0.313464463 | -0.313464463 |
| min pulse / ns | +0.549876153 | +0.549876153 |
| min period / ns | +0.408300072 | +0.408300072 |
| 原 500 MHz 四项判定 | FAIL | FAIL |

M-S setup 再改善 0.319438577 ns，面积比 M-R 少 211.12 µm²；raw min-pulse 仍为
-20.870256424 ns，实际时钟缓冲仍为 6,310 个 BUFX4H7L、+12,367.6 µm²。
两轮系统、完整 benchmark、raw STA 的来源 hash 校验一致，所有阶段 changed_inputs 为空。
原生 raw/clock 退出码 2/1 均来自真实时序失败，未改成成功或归类为执行中断。
M-R 的额外 hold 修复没有套用到 M-S，不能给 M-S 填写 M-R 的修复后 hold/面积。

指定普通 read 分支确已关闭，新最差中段变为 prepared-store 的当前资格：
保护响应 valid → LSU 当前 cached 属性 → Split → 当前 op/cached 与 prepare-valid Q
共同选择 prepare-payload Q 的地址 → DCache write-valid → AXI 首 W 信用 → Cache 状态 D。
实际小 mapped 路径对该归属有正向证据；payload 已登记，选择资格仍受当前输入控制。
它没有迁到 RR。该证据不等于全图所有 Q/消费端证明，也不支持新增 false path。
后续应重新设计这个实测控制边界，不能继续把它称为普通 read empty-flow 问题。

现有 tag18 kill 实际发生于 LSU→Physical 入口接受 E0 与最早 Cache 接受 E1 之间。
原局部说明曾把入口计数误称外部读计数，已更正。沿用原激励追加的直接观测确认：
Service Q 驻留 kill=1、此前 Cache 接受=0、kill 后恰一次接受、入口到 Cache gap=1、
排空无 WB 且 mem-issued 清除；原 coupled 总计不变。
同一早期窗口的全局 flush 仍未单独计数。

## 独立评估与默认选择

[最终独立架构选择](../../../../build/memory-rounds-20261013/final-architecture-selection.md)
维持 T1 + M-R 为生产默认：在本批两个完整 workload 上没有新增周期成本，且 setup 改善
0.263203859 ns，面积增量很小。M-R + M-S 是有实测收益的 tradeoff 候选，不应丢弃负面结果；
但它在当前固定 500 MHz 目标下仍 FAIL，且 CoreMark/Dhrystone 多花 5.44% / 7.13% 周期，
本批没有实际完成的补偿设计，因此不将其设为默认。

后续问题已由普通 read 空流移到 prepared 当前资格、完整 descriptor 选择与 store/AXI 控制。
本次只记录这个事实约束，不把关闭 prepared、给 store 加级或重新改变 RR 自动变成下一项实现。
只有架构合同与新的实测取舍支持时才决定新的候选。原 owner、精确副作用、取消排空、真实 R/B
和公平性要求继续适用，不能以负 slack 推算一个合格频率或通过放宽约束宣称完成。

## 保留点、复现与清理

本批实际完成两轮 RTL 候选，各有局部、系统、完整 benchmark、raw 综合/STA 和真实时钟缓冲
测量；另完成六轮 M-R 映射后 hold 修复。性能与时序架构设计分别在不读 RTL 的上下文完成，
新独立架构角色先核对合同，再按实际结果裁决；RTL 实现、定向取证与工具修复由其他角色负责。
本批继续使用已纳入仓库的双架构工作流，没有把局部已定位物理工具修复交给架构角色。

M-R 生产 RTL 与测试已按已测冻结文件逐字节合入。合入前目标文件无既有修改，合入前后
M-S 正在测量的 157 项输入、103 个实际 RTL 源及三份 overlay 均与其冻结记录相同。
详情见[生产合入校验](../../../../build/memory-rounds-20261013/production-mr-integration.json)。
没有为同字节复制重复跑一轮综合；M-S 仍是单独候选，生产普通 read empty-flow 参数为 1。

复现入口及每个已执行命令、实际库/工具/输入 hash、原生退出码保存在
[本批结果目录](../../../../build/memory-rounds-20261013/)：
run-candidate.py 运行各冻结 overlay 的 system/bench/sta，
run-clock-round.py 处理各自 clock 子轮，
hold-tool/run-hold-round.py 与 run-input-hold-round.py 保存六轮修复命令和父子关系。
重新需要大网表或仿真二进制时必须按冻结源重建，不能将已删除产品当作仍可执行的产物。

在时序路径和宏实例信息完成提取、所有依赖消费者退出后，调用现有 finish_round.py 与
finish_simulation.py，仅清理本批已知可再生产物。17 份原生清理记录均 cleanup_complete=true，
共释放 **2,358,444,316 bytes（约 2.36 GB / 2.20 GiB）**。
测量结果、完整日志、关键路径/宏清单、候选 patch、冻结 overlay、复现脚本和测试输入保留。
每轮原始 FAIL 和返回码保持不变。见[清理汇总](../../../../build/memory-rounds-20261013/cleanup-summary.json)。

已分别提交工具与 RTL：91e51fed3（ECOS 宏 hold 支路修复及测试），
033a1b62c（M-R refill 独立容量查询、ECOS 注释与功能测试）。本报告及架构记录另行提交，
不将大生成文件加入 Git。

## 原始结果和判断依据

- [M-R 汇总](../../../../build/memory-rounds-20261013/round1-refill-completed.json)
  与[完整 benchmark 对照](../../../../build/memory-rounds-20261013/round1-refill/full-benchmark-comparison.json)。
- [M-S 汇总](../../../../build/memory-rounds-20261013/round2-service-completed.json)
  与[完整 benchmark 对照](../../../../build/memory-rounds-20261013/round2-service/full-benchmark-comparison.json)。
- [保留的 hold 方法实测](../../../../build/memory-rounds-20261013/round1-refill-hold-input2-completed.json)
  与[首个 hold 子轮](../../../../build/memory-rounds-20261013/round1-refill-hold-completed.json)。
- [真实新路径事实](../../../../build/memory-rounds-20261013/new-path-facts.md)
  与[v2 映射边界](../../../../build/memory-rounds-20261013/forensics/round1-refill-raw-v2/architecture-summary.md)。
- [M-S 新路径事实](../../../../build/memory-rounds-20261013/service-new-path-facts.md)。
- [双架构独立评审](memory-independent-review-20261013.md)
  与[实测后的续轮裁决](../../../../build/memory-rounds-20261013/next-round-decision.md)。

这些是本次限定配置的实现、功能和 pre-layout 证据，不构成商业 CPU、完整 Ubuntu 或正式 PPA 签核。
