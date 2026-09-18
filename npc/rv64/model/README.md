# 承岳64性能模型

当前行为建模入口见 [behavior/README.md](behavior/README.md)：直接描述 always 块，
通过 I/O 连接生产模块，生成 GPU 驻留内核。Intel Arc 130T 核显已执行相连的 LSU
完成路径，两组参数共 2,400 周期与原 RTL 零差异，见 [网络结果](behavior/TERMINAL.md)。
默认网络 1,200 周期的 GPU 内核为 5.079 ms，C++ 参考循环为 1.421 ms，仍慢于 CPU；
新行为后端尚未接入整核。此前独立模块测量保留在 [核显结果](behavior/IGPU.md)。

当前可运行的整核入口见 [整核事件模型](network/CPU.md)：它从真实 RTL 导入完整 CPU，
独立执行镜像，保留原 DiffTest，并严格比较每条退休/异常和自然终止的绝对周期。
它采用原生 C++ 的字值变化调度，不依赖 Verilator 运行。详细验证和速度范围见该页；
所有生产模块的高层事务协议重构尚未完成。

**本页下面描述的是旧的 correct-path 近似模型**，它的误差结论不代表新的整核底座。
这是针对当前生产 RTL **chengyue64** 的 C++17 近似性能模型，提供参数探索和逐指令时序对照。
功能执行复用本工程 NEMU 或现有 RTL DiffTest 退休流；模型独立维护流水线、资源占用和周期。

当前仍是**未达到零误差要求的实验版**。2026-09-17 修正 LSU 地址屏障、直接/延后查询、
完成端口选择及 DIV 拍数后，同流 CoreMark 前缀的退休跨度误差由 −23.30% 降至 −2.85%，
Dhrystone 前缀仍为 −7.28%。完整 CoreMark / Dhrystone 同流对照分别低估 4.45% / 7.77%。它没有全核逐周期精度，也没有证明参数收益排序在 RTL 上保持一致。
零误差的具体约定及拒绝条件见 [EXACTNESS.md](EXACTNESS.md)。
RTL 派生 CXXRTL 后端的实际精度、速度与构建限制见 [CXXRTL.md](CXXRTL.md)。
[VALIDATION.md](VALIDATION.md) 和 validation-baseline.json 保留 v0.1 的历史测量，不代表当前版本。

没有修改生产 RTL、DiffTest 或正式 PPA 流程，也不把本模型结果作为这些流程的 PASS。

协议化网络的新实现见 [可运行网络原型](network/README.md) 和
[协议及扩展范围](network/PROTOCOL.md)。它由共同状态转移生成 C++ 与 RTL，
并用独立参考逐周期验证队列、仲裁、反压及取消；尚未接入生产 CPU，
没有改变本页 correct-path 实验模型的精度结论。

## 快速开始

在 Ubuntu/WSL 的工作区根目录执行；需要 g++、make、Python 3，NEMU 轨迹生成还需要 libreadline。
真实 RTL 微基准验证使用已构建的 SystemTestTop、参考模型和 riscv64-linux-gnu-gcc/objcopy。

    make -C npc/rv64/model -j2
    make -C npc/rv64/model test

已有本地基准镜像时，例如本次使用的 CoreMark：

    mkdir -p tmp/model-example
    npc/rv64/build/perf-model/trace-nemu \
      tmp/rv64-cpi-timing-20260916/images/coremark.bin \
      nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so \
      tmp/model-example/coremark.trace --allow-timing-inputs

    npc/rv64/build/perf-model/r64-model tmp/model-example/coremark.trace \
      --config npc/rv64/model/configs/chengyue64-v1.cfg \
      --output tmp/model-example/baseline.json

上面的镜像路径是本次工作区已有文件，不是工具依赖；可以替换为自己的裸机 ELF/raw 镜像。
trace-nemu 从 0x80000000 和复位 GPR 状态开始，装载 64 MiB RAM，复用现有 NEMU DiffTest API。
遇到 a0=0 的 EBREAK/C.EBREAK 自然结束，终止陷阱本身不计为退休指令。非零 a0、未知指令等会报错。

时间 CSR/RTC 输入默认拒绝。示例显式允许后，报告标记 trace_timing_inputs=true：
NEMU 得到的时间值可能改变打印结果或程序控制流。此类完整轨迹适合固定输入回放，
与另一条 RTL 轨迹比较前必须检查指令流一致，不能直接称为精度验证。
若程序行为依赖计时、设备输入或并发，固定轨迹也不能预测改变硬件后发生的路径变化。

--max-instructions=N 可以生成有限前缀；达到上限时工具返回 3，trace_natural_end=false，
不把前缀误报成完整程序完成。

## 参数扫描

无需重新执行 NEMU，更无需重新编译 Verilator：

    python3 npc/rv64/model/sweep.py tmp/model-example/coremark.trace \
      --vary iq=8,16,32 --vary wb_width=1,2 \
      --out tmp/model-example/sweep

每个组合生成独立 JSON，summary.csv 汇总参数、周期、CPI、进程耗时。
--set key=value 设置固定参数，--roi START:COUNT 设置按退休指令序号选取的 ROI。
ROI 为零起点；模型仍从程序开始执行以预热资源，单独输出 ROI 首末退休的闭区间跨度。
ROI 不会跳过前缀，也不是快照恢复。

单独探索延迟，例如：

    npc/rv64/build/perf-model/r64-model tmp/model-example/coremark.trace \
      --set iq=32 --set dcache_miss=40 --set early_alu_wake=0 \
      --output tmp/model-example/candidate.json

配置按命令行顺序应用，后面的值覆盖前面的值；所有实际参数都写入 JSON 的 config。
参数改变代表模型假设，并不自动生成对应 RTL，也不意味着综合面积、Fmax 或 PPA 可接受。
两个模型配置的差值若远小于该路径现有建模误差，只能作为待验证假设。

## 与真实 RTL 对照

短程序的完整运行：

    python3 npc/rv64/model/validate.py --out tmp/model-validation

这会编译 12 个程序，使用现有 SystemTestTop + NEMU 完整 DiffTest，
随后生成功能轨迹并逐条检查 PC 序列一致，比较退休周期。
已有输出且镜像、RTL、参考模型均未变化时，--reuse-rtl 仅重放模型。
不要在更换 RTL 或修改测试程序后复用旧输出。

对较大的真实程序，采集有明确范围的前缀：

    python3 npc/rv64/model/collect_rtl.py \
      --image tmp/rv64-cpi-timing-20260916/images/coremark.bin \
      --max-cycles 100000 --out tmp/model-prefix

    npc/rv64/build/perf-model/r64-model tmp/model-prefix/functional.trace \
      --config npc/rv64/model/configs/chengyue64-v1.cfg \
      --output tmp/model-prefix/model.json \
      --stages tmp/model-prefix/stages.csv

    python3 npc/rv64/model/compare.py \
      --trace tmp/model-prefix/functional.trace \
      --rtl-cycles tmp/model-prefix/rtl.cycles \
      --stages tmp/model-prefix/stages.csv \
      --output tmp/model-prefix/comparison.json

采集器读取现有 verbose 接口，不需要修改 DUT。GPR 写回重建访存地址与除法操作数，
同时保存原始退休周期。UART 可能不换行，因此解析支持串口字符紧邻 C 记录。
stdout 与 stderr 分开，避免仿真器缓冲输出把失败状态插进退休记录。

collection.json 保留 RTL 原始退出码。达到周期上限的 RTL 返回 1，
采集器仅在明确的 timeout 状态且已检查退休数完全匹配时接收前缀。
DiffTest 不匹配、断言失败、缺行或不明退出都不能作为有效采集。
采集成功表示该前缀可用，**不表示整个程序 PASS**。

已有完整 RTL 日志也可以导入：

    npc/rv64/build/perf-model/import-rtl \
      tmp/model-example/rtl.trace tmp/model-example/rtl.cycles < path/to/rtl.log

完整导入要求真实终止 PASS；不能把只剩部分日志的长跑当成完整轨迹。

精确验收需给 compare.py 添加 --require-exact，默认要求完整运行；
有限前缀需显式 --allow-prefix。逐条绝对周期或自然结束状态不满足时返回 2。
普通诊断模式返回 0 只表示报告生成成功。
两个独立执行后端可用 compare_runs.py 比较整个退休流及终止事件周期，见 EXACTNESS.md。

完整长跑可为 collect_rtl.py 设置 --max-cycles 20000000 --host-timeout 7200；
具体上限应覆盖自己的程序。自然结束与有限前缀在 collection.json 中分别标注。

## 模型内容与参数来源

功能层提供 pc、raw、next_pc、有效地址和源操作数值。C++ 时序层自行产生 fetch/dispatch/issue/
execute/result/wb/retire 时间，不用记录中的实际 RTL 周期来驱动回放。
因此同一轨迹可以跨参数复用；RTL 周期 sidecar 只用于事后误差测量。

| 子系统 | 显式状态 | 默认值/来源与精度 |
| --- | --- | --- |
| Rename/ROB/IQ | 同包 RAW、整数/浮点依赖、物理寄存器 credit、顺序退休 | ROB32、IQ16、GPR/FPR64，来自 CoreTop/Backend |
| 流水宽度 | 取指、派发、发射、WB、退休 credit | 默认均为 2，只支持 1/2；容量释放存在聚合抽象 |
| RegRead/ALU | 每 lane 队列、执行预留、终端队列、早唤醒 | RR 每 lane 3、ALU 每 lane 4；短 ALU 依赖链已对齐 |
| MUL/DIV/CLMUL | 共享单元每拍最多接受一条、终端预留、除法操作数相关周期 | MUL6 阶段/8预留；DIV 按 radix-4 状态转移计拍，CLMUL 未独立校准 |
| WB | 9 来源、保持授权、旋转优先级、LSU 请求提示、注册完成、sticky wakeup | 对照 R64Writeback；不是固定加一个“WB罚时” |
| LSU | LSQ20、较老未翻译访存屏障、store 地址依赖、完整覆盖转发、部分重叠等待、ROB-head store 授权 | 翻译/查询/完成队列聚合成延迟；未逐个复刻实际 owner/pin |
| DCache | 64B line、64 sets、2 ways、PA[3] 双 bank、单 refill、独立 store 响应占用 | hit/miss/AXI B 为聚合延迟；部分 read/store overlap |
| ICache/前端 | 64B line、64 sets、2 ways、有限前端/Decode队列 | 16B sector流水、FetchStream早期目标表、redirect drain 未完整展开 |
| 预测 | 256 bimodal、64 tagged BTB、RAS8，分支解析训练 | 正确路径上预测和恢复；不产生错误路径指令或缓存污染 |
| FP/CSR | FP寄存器依赖、粗粒度单元/串行等待 | FP 延迟为占位估计，未校准；特权状态副作用未建模 |

重点参数分三类：

- RTL 中直接可读的容量/结构：rob、iq、lsq、gpr、fpr、decode_slots、rr_slots_per_lane、
  alu_slots、mul_slots、cache sets/ways、bimodal_entries、btb_entries、ras_entries。
- 来自 RTL 边沿关系并经过短程序对照的时序：iq_init_latency=2、rr_latency=2、
  alu_latency=1、mul_latency=6、wb_register_latency=1、wakeup_latency=1、retire_latency=1。
  alu_latency=1 是接受到结果的边沿差，不是宣称 ALU 只有一个内部相位。
- 尚需更多场景校准的聚合参数：frontend_slots=24、frontend_latency=13、icache_miss=23、
  translation_latency=5、lsu_query_latency=3、dcache_hit=2、dcache_miss=24、
  lsu_completion_latency=2、store_response=11、forward_latency=3、branch_recovery=8、
  predicted_taken_bubble=1，以及 FP/CLMUL/serial 延迟。

这里的 frontend_slots=24 是抽象容量，不是某个真实 RTL FIFO 的深度。
cache replacement 用 LRU 年龄近似，写穿 store 不分配新 line；总线仲裁为聚合共享占用，
没有逐拍 AXI 通道协议，也没有完整 DCache 替换与重放状态机。
LSU 双完成源按实际接受的完成事件轮转，并维护有限前端/缓冲占用，仍未逐拍复刻每个真实队列；
FP单元共享与发射间隔也是粗粒度近似。这些会影响混合负载中的WB竞争。

每拍按 retire → WB → complete → memory → execute → issue → dispatch → frontend 更新；
显式 ready/done 时间表达主要跨寄存器边界。部分 credit 可在同一模拟 tick 复用，
因此此顺序不等价于所有 RTL 寄存器同时读取 old-Q。跨模块精确握手仍需进一步拆分 next-state。

## 输出怎么读

- cycles：从模型周期 0 到最后一条记录退休为止的周期数，包含冷启动。
- host_seconds：仅时序 run()，不含文件读取/解码；sweep 的 process_seconds 包含整个模型进程。
- stages.csv：逐条 id/pc/kind 与各阶段时间。load 的 result 是数据完成时刻，
  store 的 wb 列是旁路 store 完成事件，并不占用普通宽 WB。
- comparison.json：先检查相同 id/PC，再比较首末退休闭区间跨度、
  相邻退休间隔精确匹配比例，以及去掉起始平移后的周期误差 p50/p95/max。
  “跨度相近”不等于每条指令时刻相同。
- events：阻塞/请求/资源占用统计。不同事件允许重叠，有些按等待 owner 累加，不能相加解释为 CPI。
- unused_retire_slots：每拍未使用退休槽按当拍 ROB-head 状态归类。
  总和 + instructions = commit_width × cycles，是守恒的槽位分类；
  它描述模型当拍表象，不能据此断言真实 RTL 的唯一根因。
- trace_natural_end=false 明确表示输入只是前缀。
- trace_timing_inputs=true 表示包含环境/时间相关输入，回放固定该次路径。

不建模 MMU/TLB walk、OS/中断/异常恢复、atomic/vector/custom、非对齐拆分访存、
自修改代码一致性、完整 FENCE.I 效应、FP 数据相关执行时间。
显式不支持的指令/非对齐访存会报错；普通 FENCE/CSR 只提供粗粒度串行时序，
不是其全部微架构副作用。译码器是性能分类器，功能合法性由 NEMU/RTL 保证。

当前一次性把轨迹和每条指令状态载入内存；数百万条指令会占数百 MiB 到数 GiB。
超长程序应先用有代表性的短程序/ROI；本版还没有 SimPoint 自动取样或快照预热恢复。

## 如何用它推进优化

1. 对不依赖计时的裸机工作负载用 NEMU 快速产出轨迹；时间敏感路径用 RTL 导入固定真实轨迹。
2. 扫描资源/延迟，定位对哪些假设敏感，再检查相关阶段时间与阻塞统计。
3. 优先修正目标热点的模型结构误差，例如当前 CoreMark 多级指针访存循环，
   再讨论该热点参数变化的收益排序。
4. 少量候选回到真实 RTL + DiffTest 验证 CPI；频率、面积和 PPA 继续用原有综合/STA 流程。

可参考的开源方法：本模型采用与 [ChampSim](https://github.com/ChampSim/ChampSim) 类似的
功能轨迹与时序回放分层，但实现针对本地承岳64，未直接移植其核模型。
如果下一步必须评估错误路径执行、精确恢复及时间反馈，需要类似
[gem5 O3CPU](https://www.gem5.org/documentation/general_docs/cpu_models/O3CPU) 的执行驱动能力，
或将功能执行与本模型耦合，单靠正确路径 trace 无法补出这些信息。
本地模型的关键工作仍然是提炼实际 RTL 合同并持续校准，不是把已有模拟器默认参数改成 RV64 即可。
