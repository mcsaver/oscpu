# 整核并行状态转移实验

定位修正：本后端保留为 CPU 调度实验与语义对照；GPU 的编译和执行设计以 [GPU_DATAFLOW.md](GPU_DATAFLOW.md) 为准，不继承这里的宿主函数分组和线程屏障。

这是在真实 chengyue64 整核上运行的 **CPU 多线程后端**。它实现共享旧状态、
独立下一状态和依赖阶段同步；目前没有可运行、已验证的 GPU 后端。
它与串行整核底座共用 RTL 导入和字级计算语义，独立实现调度与状态提交。
原来的串行后端仍是默认值，生产 RTL 和原始 DiffTest 保持不变。

## 运行

在工作区根目录的 Ubuntu shell 中：

    python3 -B npc/rv64/model/network/build_cpu.py --backend parallel

默认输出 npc/rv64/build/network-parallel/r64-network，与串行输出目录分开。
运行时通过 R64_MODEL_THREADS 选择宿主线程数，包含调用线程；未设置时为 1：

    R64_MODEL_THREADS=4 npc/rv64/build/network-parallel/r64-network \
      npc/rv64/build/chengyue64/core/program.bin \
      nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so \
      --maxcycles=2000000

这里仍然只运行一个被模拟 CPU。4 个线程参与同一次仿真，不是同时运行
4 份独立程序。R64_PARALLEL 报告线程数、调度次数、实际计算组数和边沿数；
R64_ENGINE_TIMING 保留与 Verilator 相同的 eval 计时方法。

    R64_MODEL_THREADS=4 python3 -B npc/rv64/model/network/validate_cpu.py \
      --model npc/rv64/build/network-parallel/r64-network \
      --out tmp/rv64-parallel-validation

    python3 -B npc/rv64/model/network/tests/test_rtl_compile.py

    python3 -B npc/rv64/model/network/build_timed_rtl.py \
      --out tmp/rv64-parallel-timed-rtl
    python3 -B npc/rv64/model/network/benchmark_parallel.py \
      --rtl tmp/rv64-parallel-timed-rtl/r64-verilator-timed \
      --out tmp/rv64-parallel-speed --threads 1,2,4 --samples 3

计时比较完整程序的原始 Verilator、串行模型和 1/2/4 线程并行模型。
各引擎均保留完整 DiffTest、RTL 断言和设备行为；比较终止计数、统计区间
和 eval 次数，分别报告引擎时间与进程端到端时间。速度测试的终止检查
不能替代 validate_cpu.py 的逐条退休/异常周期对照。

## 执行语义

1. 输入变化首先触发组合依赖传播。一个并行阶段内的组没有跨组依赖，
   所有上游结果在阶段开始前已经稳定；组内按拓扑顺序计算。
2. 正边沿断言仍在原采样位置读取旧状态。
3. 2,399 个寄存状态字全部从同一份旧状态计算 next；线程不提前提交结果。
4. 284 个存储器各有一个写入任务。任务先把该存储器的旧内容复制到
   memory_next，再按原 RTL 导入的端口优先级依次合并写掩码。
   不同存储器并行，同一存储器的端口不会竞争写入。
5. 所有状态任务完成后，调用线程统一提交寄存器和存储器，再传播组合输出。
6. 负边沿断言保持原来的触发与采样规则。

这些宿主执行阶段不会增加目标 CPU 周期。assertion 不在工作线程中抛异常，
避免一个线程提前离开而其他线程停在 barrier。工作线程在调度之间休眠，
在一个组合任务内用带 acquire/release 的阶段屏障同步。

多个上游组可能同时通知同一后继组，因此 dirty 标志使用原子存储。
中间信号具有单一写入者；生成器检查阶段之间的实际依赖，拒绝同阶段
不同任务之间的生产者/消费者边。这个检查不能替代动态 RTL 验证。

同过程内多次非阻塞赋值的优先级和阻塞临时变量依赖由 RTL 前端保留，
再使用与串行后端相同的 cell lowering。当前仍是单时钟、两态模型；
不支持的时钟、cell、memory read 形式等会明确拒绝。完整限制见 CPU.md。

## 两种任务划分

最初按组合深度分层，宽层并行、窄层连续执行：

    python3 -B npc/rv64/model/network/build_cpu.py --backend parallel \
      --parallel-partition levels --group-size 256 --out path/to/level-build

当前默认将独立依赖链合并成任务：

    python3 -B npc/rv64/model/network/build_cpu.py --backend parallel \
      --parallel-partition cones --group-size 512

合并规则很具体：一个节点尚未完成的上游若全属于同一个任务，就可以加入
这个任务；若来自多个任务，就等下一个阶段。任务内部直接使用局部变量，
减少全局中间信号读写。--group-size 限制每组节点数，不是线程数。

真实整核导入的静态规模：

| 项目 | 按层分组 | 合并依赖链 |
| --- | ---: | ---: |
| 组合节点 | 120,334 | 120,334 |
| 原始组合依赖深度 | 92 | 92 |
| 宿主同步阶段 | 23 | 9 |
| 组合任务数 | 481 | 241 |
| 组内局部中间字 | 1,075 | 80,286 |
| 状态更新任务 | 302 | 302 |

默认分组各阶段的任务数为 51、78、38、33、26、7、5、2、1。
这比“一条赋值一个线程”保留了更大的连续计算块，但依然存在尾部串行依赖、
不均匀任务开销、线程唤醒、原子通知和缓存一致性成本。并行度不等于加速比。

## 验证与测量范围

定向测试以独立 Icarus RTL 作为参考，覆盖：

- 不同 always 块同时读取旧值；
- 同过程后一次非阻塞赋值覆盖前一次；
- 阻塞临时变量、寄存器使能与复位；
- 同地址带掩码的存储器写冲突；
- 宽位运算、可变移位、正/负边沿断言；
- 500 周期固定种子激励，串行后端及两种并行划分；
- 合并依赖链的 1/2/4 线程，以及按层划分的 1/4 线程；启用 UBSan。

整核的接受条件是原始完整 DiffTest 通过，同时所有绝对退休/异常事件与
自然终止周期相等。当前实测报告位于 PARALLEL_VALIDATION.json 和
PARALLEL_BENCHMARK.json；只对报告实际覆盖的 RTL 配置、镜像、输入和统计区间
声明零差异，不外推到任意程序或形式化等价。

2026-09-17，最终合并依赖链版本以 4 线程完成 **38/38 个场景**，共 34,530 条
退休指令、142,071 个目标周期。所有退休/异常事件与终止周期零差异。
范围包括 12 个微基准、6 个整核程序和系统 I/O 的正常/反压模式；
完整 NEMU GPR/FPR/CSR/设备 DiffTest 与 1,979 个导入断言保留。

同主机、相同 timer、各 3 次样本的 eval 时间中位数如下（单位秒）：

| 完整程序 | Verilator | 原串行模型 | 并行后端 1 线程 | 2 线程 | 4 线程 |
| --- | ---: | ---: | ---: | ---: | ---: |
| program | 0.235400 | 0.192424 | 0.207206 | 0.196678 | 0.235656 |
| throughput | 1.235237 | 1.273987 | 1.396510 | 1.268026 | 1.279809 |
| lsu_contention | 6.409755 | 5.738378 | 6.246108 | 5.475830 | 6.499017 |

2 线程相对同一并行后端的 1 线程加速约 1.05–1.14 倍。相对已经优化的
原串行模型，program 略慢，高吞吐流基本相当，LSU 竞争加速约 1.048 倍。
4 线程没有稳定加速，LSU 场景还出现明显样本波动。因此保留它作为
可验证的并行调度实验，不把它替换为默认执行引擎，不宣称已实现大幅提速。

这些是单次仿真的时延测量，未使用多程序批量吞吐替代单程序速度。
JSON 同时保存所有样本和端到端时间，eval 包含宿主调度、同步和状态提交开销。
没有 GPU 执行，因而也没有可以报告的 GPU 传输或内核执行时间。

## GPU 环境边界

本轮 Linux CUDA 探测返回 CUDA_ERROR_NO_DEVICE（100）。
检测到了 /dev/dxg 与 Windows Intel OpenCL 驱动文件，但这不等于已有
可调用、可验证的 Linux GPU 计算设备。临时编译的 Windows OpenCL 查询程序
被 Device Guard 拦截，已删除，并停止了 Windows 端尝试。

没有关闭或调整安全策略，没有添加白名单，没有安装 GPU 驱动。
因此报告不包含 GPU 执行时间，也不能把 CPU 多线程结果外推成 GPU 加速比。
任务图和旧状态/下一状态语义可用于后续设备后端；设备端代码、正确性、
内核启动、跨阶段同步与数据传输成本仍需实际实现和测量。

## 文件与清理

- parallel_compile.py：独立任务划分、next-state 和整核调度代码生成。
- parallel_runtime.hpp：持久工作线程、任务间休眠与阶段屏障。
- benchmark_parallel.py：完整程序的多引擎、不同线程数比较。
- rtl_compile.py：复用的字级语义及事件组生成接口。
- build_cpu.py：选择后端，默认隔离输出目录。

默认构建结束会删除临时网表、生成代码及对象文件。
--work 用于保留调试代码，用户明确选择后才保留；对象文件仍自动删除。
本轮额外保留的调试目录也在验证与测量结束后清理，只保留有用的可执行文件
和精简结果。
