# Intel 核显上的 always 行为执行

当前环境已实际执行，设备为 **Intel(R) Arc(TM) 130T GPU (16GB)**。
DXCore 返回 vendor=0x8086、device=0x7d51、IsHardware=true、IsIntegrated=true。
这里的名称和容量标签来自驱动描述，不作为独立显存容量结论。

当前还已接通 LSU 完成路径：三个源队列、六路选择、格式化与完成队列在同一个
GPU 实例内交互，两组参数 2,400 周期与 RTL 零差异。详细结构、新 uint32 后端、
计时和复现入口见 [TERMINAL.md](TERMINAL.md)。

上一轮优化后的单实例 Counter / 宽位 LSU queue 内核比同条件下旧 GPU 实现分别快
**16.62 / 6.55 倍**，仍比生成的 C++ 参考循环慢约 15–16 倍。尚未实现整核行为
GPU 模型，也没有超过 CPU / Verilator 的结果。

使用原生 Linux ELF 程序调用 WSL 自带 libdxcore.so、libd3d12.so，经 /dev/dxg 访问核显。
执行器要求 Intel 硬件集成 GPU；设备不存在或执行失败会直接报错，不回退到 CPU /
软件渲染。不运行 Windows 程序、不改安全策略、不安装或替换系统驱动。

## 面向 GPU 的行为编译

输入仍是 always_ir.py 的 Model / Block / Expr / Assign / Check。Counter 和 queue
使用原有行为描述，生产 RTL 不变；没有综合、门级映射或虚拟电路。

编译路径：

1. **fused_rules.py**：把有序语句转换成纯状态更新表达式。代入组合计算，合并条件
   和同一块的赋值优先级；NBA 读取共同旧状态，blocking 保留块内依赖。跨块只合并
   静态不相交位片，拒绝重叠写入。检查保留原行为块来源、条件和阶段。
2. **simd_values.py**：规范内部值的表示，显式掩码保持原位宽，让同构计算可以共享
   一条 SIMD 路径。运算最终仍由 32 位无符号整数完成，不使用浮点近似。
3. **word_projection.py**：将宽位更新按输出机器字分工。payload 等逐字独立运算
   由不同 lane 分担，避免每个 lane 重新计算整条宽 payload；进位等真实依赖保留。
4. **simd_codegen.py / wave_codegen.py**：按表达式结构形成规则族，以描述符传递
   不同的输入地址、状态地址和常量，复用共同表达式。设备内持续推进目标边沿。

这仍是行为表达式编译。源 always 块保留语义边界，但不固定等于一个 GPU 线程。
CPU 装载行为所需数据和一段输入，提交 **一次 Dispatch(1,1,1)**，最后读取结果；
中间没有 CPU 每拍调度、每拍 dispatch 或逐块回调。并行任务来自同一个模型实例，
不是同时运行许多独立模型来计算吞吐。

## 设备布局

默认 backend=auto 按当前模型的结构选择：

| 布局 | 当前用途 | 当前状态 | lane 间通信 | 正常边沿同步 |
| --- | --- | --- | --- | --- |
| wave | 小型、少规则族模型；Counter | lane 寄存器 | WaveReadLaneAt，检查用 wave 归约 | 0 次 group barrier |
| simd | 宽位或较多规则族模型；LSU queue | 紧凑 groupshared 字数组 | 共享旧状态；next 保存在 lane 寄存器 | 2 次 group barrier |
| dataflow | 具有显式保留中间值的模块网络；LSU 完成路径 | 状态及必要组合值共用紧凑共享字数组 | 依赖分批，每批内部 SIMD，next 保存在 lane 寄存器 | 默认 LSU 网络为 3 次组合同步 + 2 次提交同步 |

wave 使用 32 个 lane，交换操作放在所有 lane 都活跃的位置，之后执行各自规则；
所有需要的旧状态读取完成后再提交。当前 Counter 有 9 个状态字、3 个规则族，
共享状态和候选缓冲区均为零。

simd 显式请求 WaveSize(8)，把不同规则族对齐到不同 wave，减少同一 wave 中的
异构路径串行执行。宽位 queue 有 47 个状态字与 6 条检查，分成 13 个规则族，
补齐后分配 120 个槽位，thread group 为 128 个线程。每个状态字有唯一写入者；
共享数据为 192 字节，旧版为 836 字节。每个 lane 在寄存器中算好 next，确认检查
通过后提交；提交前后各一次组同步。包含组合 Check 的模型会增加对应检查同步阶段。

三个布局都保留检查失败的语义：phase 0 为边沿前组合检查，失败时不更新；
phase 1 为时序检查，失败时不提交该边沿；phase 2 为提交后的组合检查，
此时新状态已经生效。返回目标边沿编号、原行为块编号和阶段。

auto 首先为声明 materialize 边界的网络选择 dataflow；其他模型采用
“逻辑任务数不超过 32 且规则族不超过 4 时选 wave，否则选 simd”
的有限启发式，支持显式覆盖；它不是适用于任意未来 CPU 模型的最优性结论。
simd 当前受单个 thread group 的 1,024 个调度槽位限制。增加线程数不等于全部有效
lane，也不等于已占满整个 GPU；目前未采集硬件 occupancy / 利用率计数器。
跨组状态与环境通信尚未实现。

验证配置保留边沿前后所有输出和状态。性能配置在编译时固定关闭 trace，使编译器
删除记录路径并减少寄存器压力，**协议检查仍保留**；最后的完整状态仍会比较。

## 实际正确性结果

单模块优化测量见 [IGPU_OPTIMIZATION.json](IGPU_OPTIMIZATION.json)。
本次编译器改动后的单模块正确性回归见 [IGPU_REGRESSION.json](IGPU_REGRESSION.json)，
仍为以下 9,999 个 RTL 观察点及 400 个混合边沿零差异；另覆盖三个后端各 phase 0 / 2，
共 6 个失败阶段用例。连接网络的独立记录见 [TERMINAL_GPU_VALIDATION.json](TERMINAL_GPU_VALIDATION.json)。
[IGPU_VALIDATION.json](IGPU_VALIDATION.json) 保留旧后端的历史测量，性能比较采用
该优化轮次重新运行的 A/B 样本，而不是跨轮次相除。

| 模型 | 设备执行范围 | 独立 RTL 对照 |
| --- | --- | --- |
| R64Counter | 2,000 周期，4,000 组边沿前后观察 | 排除第一次复位前 RTL 未知态，3,999 组全部一致 |
| R64LsuRequestQueue，DATA_W=157、AGE_W=1、原取消模式 | 1,500 周期，3,000 组观察 | 所有输出及 19 个内部状态字段全部一致 |
| R64LsuRequestQueue，DATA_W=193、TAG_W=12、ROB_W=6、AGE_W=32、预备取消模式 | 1,500 周期，3,000 组观察 | 所有输出及 19 个内部状态字段全部一致 |
| 宽位与混合边沿语义模型 | 400 个正/负边沿，800 组观察 | 与 Python 有序行为解释器一致；此项不是生产 RTL 对照 |

合计生产 RTL 对照为 **5,000 周期、9,999 个有效观察点，零差异**。
真实 GPU 负向用例覆盖 credit 违规和 prepared-cancel 不一致；credit 失败后最终
状态保持在上一成功边沿。原优化报告对 simd 和 wave 验证了 4 个 phase 0 / 2 用例，本次回归增加 dataflow 后为 6 个。

队列 RTL 对照启用原 R64_ASSERT；测试平台显式统一两态初始条件，包括 RTL 未复位
的 payload 存储，生产 RTL 本身保持不变。Counter 覆盖字节进位边界、完整回绕、
复位、写入、使能和随机增量；队列覆盖拥塞、反压、同拍出入队、取消、flush 与 age 清除。
主机回归另有 25 项，包含新融合/字投影与原有序解释器之间的对照。

## 性能结果及限制

以下为同一核显、单个模块、单实例、关闭 trace、各 5 次运行的中位数。
新旧 GPU 后端均采用关闭 trace 的编译特化，使用同一刺激与检查，均验证完整最终状态。
内核时间来自 GPU timestamp；整进程包括启动、文件装载、设备与 pipeline 初始化、
dispatch 和输出。编译时间单独记录，不计入运行时间。

| 模型 | 目标周期 | 旧 GPU 内核 | 新 GPU 内核 | 内核加速 | 旧 GPU 整进程 | 新 GPU 整进程 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Counter | 2,000 | 60.386 ms | 3.634 ms | 16.62× | 483.416 ms | 125.217 ms |
| 宽位 LSU queue | 1,500 | 35.621 ms | 5.439 ms | 6.55× | 523.625 ms | 436.412 ms |

| 模型 | 新 GPU 内核 | C++ 行为参考循环 | GPU / C++ 时间比 |
| --- | ---: | ---: | ---: |
| Counter | 3.634 ms | 0.225 ms | 16.15× |
| 宽位 LSU queue | 5.439 ms | 0.354 ms | 15.38× |

C++ 由原有序行为代码生成器产生，使用 g++ -O3；表中 C++ 时间只计状态推进循环。
新后端确实改善了 GPU 执行结构与单实例时间，但这两个小模型仍不足以提供整个 GPU
需要的并行工作量，尚未超过 C++。没有与 Verilator 整核比较，也没有整核 CPI 数据。

LSU 完成路径现已将真实相连模块及其输入反馈放入设备模型，结果独立列于
[TERMINAL.md](TERMINAL.md)。其余 CPU 模块、跨组依赖与精确提交仍需继续扩展。
还需要复用 device / pipeline，降低短任务整进程开销；不能从表中推算整核加速比。

## 使用

在工程根目录的 Ubuntu shell：

    make -C npc/rv64/model behavior-igpu
    make -C npc/rv64/model test-behavior-igpu

前一命令在项目 build 目录准备 Linux DXC、DirectX headers 和原生执行器。
下载来源固定为 Microsoft DirectXShaderCompiler 官方发行包、Ubuntu 官方 header 包；
来源记录在 build/behavior-d3d12/deps/sources.json。不运行 apt install，不要求 root。
默认 header 包对应当前 Ubuntu 24.04 环境。

后一命令实际访问核显，默认采用 auto 后端，运行对照、负向检查与计时，
更新 IGPU_OPTIMIZATION.json。没有硬件时会失败，不会把主机执行标记成 GPU PASS。

复现包含旧 GPU 后端的 A/B 测量：

    python3 -B npc/rv64/model/behavior/validate_igpu.py --compare-baseline

只运行正确性对照，并把报告放入另外的路径以保留性能记录：

    python3 -B npc/rv64/model/behavior/validate_igpu.py --skip-benchmark \
      --out tmp/igpu-correctness.json

支持 --backend auto|simd|wave|baseline；手动选择可能不适合某模型，失败会明确报告。
Python 入口 d3d12_backend.compile_model 同样默认 auto，返回 emitter、DXIL 路径和
编译时间，也支持显式 backend="dataflow"；emitter.metadata() 提供规则族与布局信息，生成的 model.hlsl 可供检查。
execute 使用对应 emitter 提供的描述符和输入布局。

hlsl_codegen.py 仍是独立保留的旧 baseline 源码生成器；优化路径通过 compile_model
使用 simd_codegen.py / wave_codegen.py；模块网络采用 dataflow_codegen.py，
其原生整数表达式由 native_codegen.py 生成。CUDA 旧后端仍独立保留。

执行器及 compiler/header 依赖保留供后续使用。验证的临时 HLSL、DXIL、输入/输出和
C++ 参考程序都放在 TemporaryDirectory 内并自动清理；保留的是报告，不是测试编译垃圾。

参考：[Microsoft WaveReadLaneAt](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/wavereadlaneat)、
[Microsoft Shader Model 6.6 WaveSize](https://microsoft.github.io/DirectX-Specs/d3d/HLSL_SM_6_6_WaveSize.html)、
[Intel GPU 线程映射与占用率](https://www.intel.com/content/www/us/en/docs/oneapi/optimization-guide-gpu/2024-2/thread-mapping-and-gpu-occupancy.html)。
