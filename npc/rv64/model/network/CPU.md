# 承岳64整核事件模型

共享旧状态、并行下一状态的实验后端见 [PARALLEL.md](PARALLEL.md)。
这是 CPU 多线程实验；GPU 设备执行尚未实现和验证。

本目录现在包含能够**独立执行整个 CPU 和系统互连**的 C++ 模型。它从当前
chengyue64 的真实 RTL 导入全部模块，读取与原 SystemTestTop 相同的镜像、
外设输入和复位序列，独立计算取指、错路执行、译码、重命名、发射、执行、
写回、提交、访存、缓存、地址翻译、CSR、异常和平台状态。

模型运行时不链接 Verilator/CXXRTL，也不读取参考退休轨迹或 RTL 周期表。
NEMU 仍作为原测试程序的独立 GPR/FPR/CSR/设备 DiffTest 参考。
这是整核精确执行底座；它与旧的 correct-path 近似模型是两条独立路径。

**协议迁移边界：** 当前整核底座自动保留真实模块 I/O 及详细状态转移，
还没有把所有生产模块改写成 PROTOCOL.md 中的高层事务节点。
semantics.py 中的队列/轮转原型仍是独立的同源生成示例。
“能模拟整核”不能解释为“所有 RTL 已完成协议重构”，也不能据此声称
任意容量/延迟旋钮都有可直接综合且周期精确的对应硬件。

## 构建和运行

在工作区根目录的 Ubuntu shell 中：

    make -C npc/rv64/model cpu-network

依赖本工作区的 oss-cad-suite（Yosys + slang）、Python 3、clang++、
GNU make、libreadline；验证额外使用当前 Verilator 系统可执行文件、
NEMU reference 和 riscv64-linux-gnu-gcc/objcopy。
默认输出 npc/rv64/build/network-model/r64-network。

直接运行自己的镜像：

    npc/rv64/build/network-model/r64-network \
      path/to/program.bin \
      nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so \
      --maxcycles=2000000

原 harness 的 --stalls、--system、--load、UART、block 等选项保持原含义。
达到周期上限、DiffTest 失败和 RTL 断言失败均为失败；只有程序自然成功终止
才记为完整运行。运行末尾 R64_ENGINE_TIMING 报告模型 eval 调用次数和累计时间。
逐指令日志与计时分别写 stdout/stderr，采集时应分别重定向，避免缓冲日志相互插入。

    make -C npc/rv64/model test-network-compiler
    make -C npc/rv64/model test-cpu-network

整核验证会重新构建 12 个微基准和 6 个仓库整核程序，运行正常/反压两种模式，
再运行系统 I/O 程序；两种引擎分别执行相同输入。比较每个退休事件的绝对周期、
PC、原指令、结果和下一 PC，每个异常事件，以及自然终止周期和计数。
同一个原始 NEMU DiffTest harness 在两端均完整保留。
测试矩阵见 CPU_VALIDATION.json，不将未运行程序或配置算作已验证。

只跑一个场景：

    python3 npc/rv64/model/network/validate_cpu.py \
      --model npc/rv64/build/network-model/r64-network \
      --micro compressed --core '' --modes plain --skip-system-io \
      --out tmp/rv64-network-one-case

## 执行语义

rtl_snapshot.py 准备独占的源文件副本，仅处理验证观测端口和断言语法。
生产 RTL、filelist、DiffTest、综合与 STA 输入不修改。
原 $fatal 的触发条件和时钟边沿保留为断言；不支持的 cell、时钟、
存储器端口规则、未驱动信号和组合环会报错。

rtl_compile.py 把 Yosys word-level 图变成原生 C++：

1. 每条输入/组合输出/寄存器信号使用定宽无符号字表示，明确截断与符号扩展。
2. 存储器每个读端口单独建立组合依赖，避免将独立端口合并后制造虚假的环。
3. 拓扑调度把组合图划成 471 个计算组；输入、寄存器或存储字变化时标记相关组。
4. 一个组只在依赖变化时计算。输出变化继续通知下游组；没有变化的路径不重算。
   87,527 个只在组内使用的中间字成为局部变量，避免反复写全局信号数组。
5. 正边沿全部 next-state 使用同一份旧状态求值，随后一起提交，再传播新输出。
   存储器写优先级按原端口顺序执行，写操作不会改变其他状态更新看到的旧读值。
6. 正/负边沿断言分别在原来的采样边沿检查；重复 eval 不会重复推进状态。

事件是**字值变化导致的计算事件**。目标时钟仍逐周期推进，
还没有跨空闲目标周期跳跃。跳跃之前必须处理计数器、定时器和外部事件，
不能只因为执行单元空闲就省掉目标周期。

当前导入规模：405 个层级模块、120,334 个组合节点、
2,399 个寄存状态字、5,487 个存储字、1,979 个展开后断言。
寄存状态字包含验证观察状态，不是 CPU 架构寄存器个数。
固定两态零初始化与当前 Verilator 基线保持一致；不模拟四态 X/Z 传播，
不构成形式化等价证明。当前支持该 CPU 的单正边沿状态更新和双边沿检查；
其他时钟/锁存器/同步 memory read 等未实现形式会明确拒绝。

## 准确性与速度

验收结果以 [CPU_VALIDATION.json](CPU_VALIDATION.json) 和
[CPU_BENCHMARK.json](CPU_BENCHMARK.json) 为准。

2026-09-17 最终版本：**38 个完整运行全部通过**，共 34,530 条退休指令、
142,071 个目标周期。所有退休/异常事件及终止周期完全相同：

| 运行范围 | 模式数 | 结果 |
| --- | ---: | --- |
| 12 类微基准：依赖、分支、访存、乘除、压缩指令等 | 24 | 零差异 |
| program：整数、FP/FMA、原子操作、CSR、异常返回 | 2 | 零差异 |
| Sv39 地址翻译 | 2 | 零差异 |
| sdtrig 触发器 | 2 | 零差异 |
| LSU 竞争 | 2 | 零差异 |
| 后端资源竞争 | 2 | 零差异 |
| 高吞吐整数流 | 2 | 零差异 |
| 系统 UART、额外镜像、陷阱和自然关机 | 2 | 零差异 |

同主机、相同 timer、三次样本的纯 eval 时间中位数：

| 完整程序 | Verilator | 模型 | Verilator 时间 / 模型时间 |
| --- | ---: | ---: | ---: |
| 综合 program | 0.240105 s | 0.217168 s | 1.106× |
| 高吞吐整数流 | 1.248250 s | 1.316898 s | 0.948× |
| LSU 竞争 | 6.596014 s | 6.071092 s | 1.086× |
| 后端资源竞争 | 0.984559 s | 0.825426 s | 1.193× |

当前没有获得普遍的大幅加速。三类程序略快，高吞吐整数流约慢 5.5%；
后续高层事务节点抽象仍有必要。端到端时间和各样本保存在 JSON 中。

只对实际运行的程序、输入、初始化与对应 RTL 配置声明零误差，
不外推到完整 Linux、所有 ISA 测试、tensor 系统顶层或未来 RTL 修改。

相同输入下逐条退休周期相等且退休数量相等，才能得到相同统计区间的 CPI。
没有使用 CPI 偏差补偿、固定周期扣减、提前读参考结果或强行对齐起始点。

速度测量使用同一个 timing.hpp 包装器，分别统计原 Verilator 和本模型的 eval：
保留 RTL 断言、NEMU、设备及原 harness 的完整工作，关闭逐条 verbose 日志。
同时保留进程端到端时间；取三个独立样本的中位数，交替运行顺序。

    python3 npc/rv64/model/network/build_timed_rtl.py \
      --out tmp/rv64-timed-rtl
    python3 npc/rv64/model/network/benchmark_cpu.py \
      --model npc/rv64/build/network-model/r64-network \
      --rtl tmp/rv64-timed-rtl/r64-verilator-timed \
      --out tmp/rv64-network-speed

build_timed_rtl.py 只在自己的临时目录重编译 harness/runtime，
复用现有断言开启的 Verilator 设计库，不修改正式 Verilator 可执行文件。
需要先确保正式 Verilator 构建与模型导入的是同一份 RTL。
不能用旧 trace 模型的“只消费轨迹”耗时来作这组速度比较。

首次完整构建实测约 221 秒，其中 RTL 导入约 157 秒、代码生成约 4.7 秒、
原生编译约 58 秒。最终局部变量优化复用相同导入网表，生成加编译约 60 秒。
这些记录属于本次实际构建，未来主机负载/版本可能改变耗时；
构建时间与执行速度分别报告。

## 架构优化的使用边界

现在可以用这条整核底座检验协议迁移，精确定位第一次退休/异常分歧。
模型使用全执行路径，因此修改前端、分支预测或访存时，不依赖旧程序轨迹。
修改生产参数或结构后，需要重新导入并构建，不能给模型随意改一个延迟值
却仍称它与原 RTL 零误差。

下一步高层协议迁移应以真实 WB 的注册 grant、request hint、完整 owner
查询/授权语义为起点；原型 rr_hold 与生产 WB 的行为不同。
逐个子网用同一套事务状态转移生成模型与 RTL，并与迁移前 RTL 三方比较。
当前整核模型提供精确的其余节点，允许替换一个子网时仍执行完整程序。

## 文件和清理

- build_cpu.py：导入、生成、编译和原 harness 适配。
- rtl_compile.py：类型检查、依赖图、边沿更新和事件传播。
- rtl_snapshot.py（上一级）：共享的验证源副本准备逻辑。
- validate_cpu.py：完整程序的严格事件和终止对照。
- benchmark_cpu.py / timing.hpp：相同 eval 计时和端到端测量。
- tests/test_rtl_compile.py：与独立 Icarus 的定向/随机对照，
  小组跨边界调度、存储器冲突、宽位运算、采样及断言检查，并启用 UBSan。

默认构建目录仅保留可执行文件、模块 I/O 清单、断言来源和精简构建报告/日志。
临时源副本、大型 JSON 网表、生成 C++、对象文件在构建结束后自动删除。
--work 仅用于显式保留后端调试源；对象文件仍会删除。
--netlist 允许显式复用已导入网表，调用者需确保它对应期望的 RTL；
正常使用优先从真实源文件完整构建。工具不会清理生产 RTL 的其他构建目录。
