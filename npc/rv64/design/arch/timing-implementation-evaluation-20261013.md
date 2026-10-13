# 2026-10-13 双路架构设计后的实现与多轮评估

状态：**两轮 RTL/配置实验、完整功能/CPI、原始综合与同口径 clock-buffer STA 均已完成。**
最终默认保留 T1；T2-min 保留为可复用实验点，不改变默认 RR direct 配置。
T1 有实际断链与 setup 改善，但完整 CPI 上升，**500 MHz 仍 FAIL**。

## 范围与比较方式

工作树为 /home/lyg/PA/ysyx-workbench，分支 ai。实现起点为 c7e3cda7ee5d；
其 RTL 与已测 e44dac90b 基线一致。基线复用 2026-10-12 protection 与 clock 实际结果，没有重跑或改写时间。
共同采用 ICS55 + ECOS SRAM、TT 1.2 V / 25°C、500 MHz / 2 ns 和原 0.05 ns uncertainty。
原断言、NEMU DiffTest、程序 oracle、CoreMark 10 迭代及 Dhrystone 10000 迭代均保留。
面积作为观测项，不设本轮面积淘汰线。

[双路设计独立评估](parallel-architecture-review-20261013.md)推荐先试 T1，再依据目标路径及完整代价选择后续。
本次完成两个实际候选的实现与功能/CPI 测量，T2 以独立源覆盖副本作受控比较，未将全部预列方案叠加。
T2 综合与 T1 后段错开并行启动，以取得同约束直接对照；是否保留仍依据最终 mapped 路径及完整结果。

| 点 | 父点与主要改动 | 状态/容量合同 |
| --- | --- | --- |
| 基线 | 已测 protection + 原 direct-admit | 原公告和当拍直接读值路径 |
| T1 | 基线 → 最终 load 公告全包登记 | 两 lane 的 valid/full-tag/data 整体 Q，默认共 148 bit；无完成 owner、无 ready/ack，II=1；消费处用当前 owner 重认证 |
| T1 + T2-min | T1 → 关闭三类 direct-admit/read 选项 | 每 lane 复用 1 ingress + 2 terminal，IQ 接受后先登记 source/owner；不实施原设想的第二 capsule；保留 resident MEM 当前真值捕获 |

T1 无效拍也登记 payload，不以 raw 数据旁路恢复旧组合链。notice 到达时 owner 已由 WB 终结、
kill/flush 或复用而无效时，消费者依靠已有合法快照、WB/history 或 canonical PRF 回退。
T2 稳态可 transfer/refill 并行，满 terminal 队列首次 pop 时仍采用保守 Q credit，可能延后一拍接收。
稳定 II=1 与短 RAW 延迟是不同指标；没有把局部吞吐结果外推为整核 CPI。

## 已完成的功能与性能测量

两个新候选各自完成 10 个 system 场景及 7 个双发射热窗口；全部通过原断言及 DiffTest。
七个热窗口均为 768 instructions / 384 cycles，即 CPI 0.5。下面是独立的完整程序结果：

| 工作负载 | 点 | cycles | commits | CPI | 相对父点 | 相对原基线 |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| CoreMark 10 | 基线 | 4,223,831 | 3,218,537 | 1.312345019 | — | — |
| CoreMark 10 | T1 | 4,423,886 | 3,218,537 | 1.374502142 | +4.736340% | +4.736340% |
| CoreMark 10 | T1 + T2-min | 4,616,448 | 3,218,537 | 1.434331188 | +4.352779% | +9.295282% |
| Dhrystone 10000 | 基线 | 5,792,104 | 4,260,629 | 1.359448100 | — | — |
| Dhrystone 10000 | T1 | 6,033,084 | 4,260,629 | 1.416007824 | +4.160492% | +4.160492% |
| Dhrystone 10000 | T1 + T2-min | 6,418,541 | 4,260,629 | 1.506477330 | +6.389054% | +10.815362% |

四次新完整 benchmark 均 PASS，commits 分别与基线相同。增加流水边界已经产生可测 CPI 成本；
峰值双发射吞吐保持，不能解释成真实程序没有性能代价。

完整计数也不支持单因归结：T1 的 Dhry branch/prediction redirect 较基线增加 9,996/10,000；
T2 相对 T1 只增加 4/2，但 frontend_empty 仍增加 19,939，WB backpressure 下降 174,927，
总周期却增加 385,457。T2 CoreMark 的 branch/prediction redirect 增加 474/542。
计数不是互斥或可加和的周期分解；Execute 宽度、issue_one 和 load/RR 专项 profile 未采集，
缺失项不能填零。详见[完整程序计数对照](../../../../build/arch-impl-20261013/full-benchmark-counter-comparison.md)。

定向验证包括：

- T1：14 项正向测试、1 项预期失败对照及严格 Core lint；两 lane/连续公告、invalid payload、
  WB 重叠、kill/flush、旧 generation、同 preg 复用和消费者唯一完成。独立事件 ledger 检查 463 次。
  关闭 Q 的同一 oracle 会在第 6 周期失败，证明新增边界检查可检出原直通行为。
- T1 的原 Q=0 精确延迟仍受原测试覆盖；Q=1 最早 raw load→Execute 从 1→2 拍，
  resident 路径从 3→4 拍；规范 CQ/WB 仍为 response+2/+3。
- T2-min：13 项候选正向、2 项 T1 同 fixture 对照、1 项预期失败对照及严格 overlay Core lint。
  native 边界检查 449 次；直接接受沿只写 ingress，老 ingress 与新 IQ payload 不混用。
  打开 direct 的同一 oracle 在第 4 周期失败。
- T2 最早 raw load→ALU/MEM Execute 从 2→3 拍；canonical WB→Execute 从 1→2 拍；
  分支 Execute 从 2→3 拍、resolve 从 4→5 拍。规范 CQ/WB 时点不变。
  WB history、FP 三读源、恢复与复用均有对应定向测试。

两份独立实现复核没有待修正 findings，但保留了证据范围：T1 某一 fallback 窗口可使用先前 notice history，
不能把四种窗口全部称为“仅 WB”；T2 局部 RAW gap=1 使用 mock lifecycle 的即时授权 WB，
不证明真实整核 WB 传输的 RAW 间隔。测试未覆盖所有 ISA/恢复组合，也不是完整 Linux/正式 release 验收。

## 同源边界与原始记录

结果位于 [build/arch-impl-20261013](../../../../build/arch-impl-20261013/)。
T1 system 与 STA 启动后，测试 Makefile 的 TESTS 列表新增了一个独立测试名。
因此 system 原生命令返回 0，而宽范围输入检查记录 runner 返回 125；原记录没有改写。
精确移除该单一 token 后，Makefile 内容与开始时完全一致；生产 RTL、系统源及综合输入未改变。
后续 benchmark 使用同一已编译仿真器，并保存了这项窄范围 reconciliation。
不能把三阶段的整个宽范围输入清单称为逐字一致，也无需因无关测试名称重新运行整核 EDA。

T2 只有 CoreTop 的三个参数覆盖，system/bench 的编译源清单实际使用该副本，两阶段输入稳定。
每轮完整程序共用各自 system 编译的同一个仿真器。来源、命令、返回码与对照 patch 均保留。
最终提交前，仅在 R64ExecutionDomain 补入一行 ICS55/ECOS TT 25°C、500 MHz 的设计目的注释。
精确去掉该行后，三个生产 RTL 文件均与 T1 实测内容逐字一致；T2 覆盖源未应用。
[测后源码说明](../../../../build/arch-impl-20261013/final-source-note.json)与小 patch 保留该差异，
原测量来源和返回码保持原样，无需因这条注释重跑仿真或 EDA。
具体局部证据与限制见 [T1 独立复核](../../../../build/arch-impl-20261013/t1-independent-implementation-review.md)、
[T2 独立复核](../../../../build/arch-impl-20261013/t2-independent-implementation-review.md)。

## 时序、保留裁决与物理边界

下表统一采用最终 flat 网表和相同的真实时钟缓冲处理，不能混入清理前层次综合面积：

| 点 | Setup slack ns | Hold slack ns | Pulse slack ns | Period slack ns | 映射单元面积 µm² | 500 MHz |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 基线 + clock | −3.226368427 | −0.313464463 | +0.549876153 | +0.408300072 | 2,414,770.140301 | FAIL |
| T1 + clock | −2.549148798 | −0.313464463 | +0.549876153 | +0.408300072 | 2,415,687.980301 | FAIL |
| T1 + T2-min + clock | −2.549148798 | −0.313464463 | +0.549876153 | +0.408300072 | 2,399,191.500301 | FAIL |

T1 setup 改善 0.677219629 ns；最终 flat 面积增加 917.84 µm²（buffered 口径约 0.0380%）。
两点 raw 面积分别为 2,402,402.540301 与 2,403,320.380301 µm²，
均插入 6,310 个实际 BUFX4H7L，面积增加 12,367.60 µm²。
T1 raw pulse 与基线同为 −20.870256424 ns；buffer 处理修复该脉宽项，并未使 setup/hold 通过。
ICache 两个 256×128 宏、DCache 四个 256×64 宏在两点实际网表中保留。

实际 mapped 检查确认 T1 的两 lane 共 148 个独立 FF，逐位 raw→D、Q→后续实际 IQ/RR FF D 连接齐全；
从 raw notice 根出发、遇顺序边界停止的保守图中，IQ/RR 公共 alias 可达数为 0。
这支持公告整包断链，不是形式等价或全部 Memory 控制隔离证明。
新 worst 从受原 0.4 ns input-delay 约束的 rst_i 出发，经保护响应、LSU 物理描述符、
split/service 空流请求路由、DCache bank 1 read/write-ready 到 bank 0 way 0 的 overlay 数据快照。
它已离开原 RR shift 链；跨 bank 链未做逻辑 sensitization 证明，不得自行 false-path。
[映射语义复核](../../../../build/arch-impl-20261013/forensics/t1-raw/semantic-review.md)
与[架构摘要](../../../../build/arch-impl-20261013/forensics/t1-raw/architecture-summary.txt)保留具体证据和范围。

T2 raw 的 setup/hold/pulse/period 分别为 −2.549148798 / −0.313464463 / −20.870256424 / +0.408300072 ns，
与 T1 raw 一致；最终 flat raw 面积为 2,386,823.900301 µm²。T2 三阶段实际输入稳定，没有 T1 的测试列表变化。

T2 的局部边界也真实生效：36/36 位 ingress source Q 均为实际 FF，逐位 IQ→D、Q 后消费齐全，
T1 的 148 位公告 Q 保留。固定的 512 个 terminal GPR 数值 FF 与 24 个 shift FF 都已定位；
T1 每 lane 当前 IQ source 可达本 lane 256 个 GPR D、12 个 shift D，T2 对同一组语义端点的
组合可达数为 0，held-ingress 值捕获也不再由当前 IQ source 直达。
T2 的全局 worst 语义、公共路径 landmark 与 arrival 均与 T1 一致，仍是同一条 Memory 链。
见[T2 映射摘要](../../../../build/arch-impl-20261013/forensics/t2-raw/architecture-summary.txt)。

**最终选择 T1 为当前实验默认与后续时序收敛父点。** 它切断原限制链并改善 setup；
该选择接受已测 4%–5% CPI 成本，不称运行时间加速。T2 切断第二段局部链，但未改善当前全局时序，
相对 T1 又增加 CoreMark/Dhry CPI 4.35%/6.39%。它约省 0.683% 面积，保留候选源、patch 与结果，
在后续 Memory 瓶颈解除且 IQ/RR 真正限制周期时可重新比较；本次不启用它为默认。
不能把 T2 称为机制失败或全局 Pareto 受支配：面积略省，功耗未测，目标域单独 ns 收益也未测量。
[独立实测架构裁决](../../../../build/arch-impl-20261013/measured-architecture-review.md)记录这些取舍。

下一轮有依据的问题是：物理 service 空流前后是否存在可承接完整 descriptor/唯一 owner 的持有边界，
以及 bank 1 ready 对 bank 0 overlay 的依赖是否来自真实共享资源、能否以更局部的登记信用表达。
这两项尚需有界取证后形成实现合同；原 ICache SRAM hold 也仍需单独收敛。
不直接豁免 reset 路径、不改原 SDC，不为实验数量继续叠加 T3/P1 或扩大 capsule。

所有点均为 pre-layout ideal-clock 口径，没有布线寄生或物理 CTS，不由 WNS 推导合格 Fmax；
当前没有 activity-based 功耗测量。

## Agent 工作流的实际收益与配置

本轮将精简做法加入现有 [CPU Architect 路由](../../../../.github/instructions/cpu-architect-routing.instructions.md)，
没有新增插件、角色框架、模型配置或审批步骤。只有同时存在周期边界与 CPI/进度的开放结构取舍时，
才并行启动两个干净架构上下文；双方只读取同一事实摘要和架构材料。
设计后由新的独立架构上下文检查合同交互；实现、RTL 取证和执行继续由独立角色承担。

本次方法产生了可核实的工程价值：设计评估发现 P1 等待环、T3 独立 producer 身份来源缺口、
P2 位置/容量/带宽混杂；实现取证又澄清现有 ingress 容量和 II，避免盲目扩容。
实现侧审查收窄了 fallback 与 mock RAW 的外推。它们支持保留这种有条件的协作方式。

没有单 agent 对照，未测量受控的注意力、token、耗时或生产率差异，不能声称量化效率提升。
方法有用与硬件候选有收益分别判断；架构评审不替代真实功能/CPI/STA。
新增路由还规定明确父点、分离主要实验变量、反馈实际新路径和完整 CPI，以及结果分析后清理大产物。

## 产物保留

已完成的局部仿真与两轮 system obj 按 finish_simulation 精确清理，共回收 1,078,956,370 bytes；
原记录按实际清理动作去重，未重复计入别名。结果、失败诊断、小型候选源/patch 和命令保留。
T1 raw/clock 在映射取证及正向对照完成后回收 443,568,860 bytes；
T2 raw/clock 在同端点对照完成后回收 438,637,144 bytes。
**本批合计回收 1,961,162,374 bytes，约 1.96 GB（1.83 GiB）**。
四个 EDA 清理记录均为 cleanup_complete=true，原 timing FAIL 返回码保留。
大网表、VVP 和两轮 system obj 均已清理；时序报告、映射 witness、宏实例清单、功能/性能结果和小复现输入仍在。
