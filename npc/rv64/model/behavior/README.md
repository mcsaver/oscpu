# 从 always 块描述 CPU 行为

基本单位是行为块，直接保留触发条件、有序语句、输入读取、局部变量与状态写入。
不调用综合工具，不生成门级网络，不经过 AIG、LUT 或虚拟布尔处理器映射。

当前已有 **行为 IR、生产模块描述、I/O 连接层及直接消费行为 AST 的 CUDA / HLSL
源码生成器**。Intel Arc 130T 核显已执行相连的 LSU 完成路径：三个源队列、六路
轮转选择、结果格式化与完成队列，全部内部反压和优先级反馈由 GPU 推进。
两组参数共 2,400 周期、4,800 组完整观察与原 RTL 零差异，见 [TERMINAL.md](TERMINAL.md)。

新 dataflow 后端保留必要中间值，按依赖分批执行，将宽表达式直接降为原生 uint32
代码；默认网络为 256 线程、772 字节共享数据，一个实例、一次 dispatch 内跨周期
执行。1,200 周期的内核中位耗时 5.079 ms，C++ 参考循环为 1.421 ms，仍未超过 CPU。
此前独立 Counter / queue 的 GPU 优化与本次兼容回归见 [IGPU.md](IGPU.md)。
**尚无整核行为 GPU CPI 或超过 Verilator 的结论**。
CUDA 内核已编译、链接但未执行 CUDA；以下 CUDA 章节仍描述独立保留的旧后端。

## 行为表示

- Model 声明输入、状态、组合值和观察输出。
- Block 保留名称、来源、comb/posedge/negedge 触发及有序语句。
- Expr 是显式位宽的无符号行为表达式，保持加减、比较、选择、截取、拼接等运算。
- blocking 在块内立即更新局部环境；局部和组合值可以整值或部分写入。
- nba 只累积待提交写入；后续 RHS 不读取待提交状态。
- If 保留分支和语句次序，Check 保留检查发生的位置。
- Patch 记录目标、写掩码、值和来源块，供解释器的提交阶段消费。

同一边沿的所有块读取同一份已稳定快照。同一块的 NBA 按语句顺序合并，后一次覆盖
相同位；不同块可以写同一寄存器的不相交静态位片。跨块重叠写入明确拒绝。

支持 1..4096 位两态值，动态 packed 位/片选择、移位、动态 NBA 地址和部分 blocking
写入。动态地址在语句执行时取值，后续局部变量修改不会改变已排定的写入。
动态写入保守占有整个目标，防止遗漏跨块冲突。部分 blocking 写入前须有整值初始化。

两态规则规定：动态读取超出范围的位为零，写入超出的位不生效；这不是完整四态
Verilog 的 X 传播语义。部分越界写入保留范围内位。宽移位量不会截成较小索引。
源 RTL 的存储数组目前由具体模块描述显式展开，不代表已支持一般数组或存储器语言。

## 真实模块

counter.py 描述生产 R64Counter 和 R64CounterNear：

- 保留 21 个 near_wrap_q 位更新块和 1 个 value_o 更新块。
- 保留 64 位计数值及 7 组 3 位进位缓存状态。
- 保留 reset > write > advance 优先级及同边沿读取旧缓存的行为。

lsu_queue.py 描述生产 R64LsuRequestQueue：

- 保留双 lane、每 lane 两项、head、valid、tag、ROB one-hot、payload 和 age。
- 保留 4 个槽位存储更新块、1 个占用状态更新块及组合控制、原有协议检查。
- 空闲槽可以在没有 in_fire 时预先捕获 payload；发布有效状态是另一个动作。
- ready 使用当前占用；取消、出队、入队与 head 选择按原语句顺序处理。
- reuse_block 和 held_age 观察当前有效条目；age_clear 的时序也保持不变。
- 支持 DATA_W、TAG_W、ROB_W、AGE_W 和 PREPARED_CANCEL 参数。

lsu_terminal.py / lsu_completion.py / compose.py 将三个生产队列、轮转事件选择与
完成队列接成一段有反馈的网络；父模块连续赋值按相同位宽和优先级描述。保留全部
69 个状态字段。内部 credit/grant 不由宿主每拍输入，详见 [TERMINAL.md](TERMINAL.md)。

生产 RTL 未修改，行为描述目前人工编写，**未实现任意 Verilog 的自动解析**。

## CUDA 设备执行

cuda_codegen.py 从行为 AST 生成 C++/CUDA，device_bits.hpp 提供精确无符号运算。
生成代码保留行为表达式与语句，不先转换成门级或位级网表。设备执行过程为：

1. CPU 一次装载一段输入。每条输入带有 posedge/negedge 标识。
2. 单个 CUDA thread block 内保持两份状态、组合值及独立候选写入。
3. 组合块根据依赖分层；同层块可并行，层间使用设备屏障。
4. 同一边沿的时序块读取共同旧状态，各自更新自己的候选字段。
5. 屏障后，每个状态字段只由一个设备任务合并并写入下一状态。
6. 稳定更新后的组合输出，再推进下一条边沿输入。循环位于内核中。
7. 最后取回记录；中途检查失败时返回发生的边沿编号、行为块和阶段。

同一个机器字被多个块分别更新不同位时，设备也不直接竞争写入。候选字段初始化
为旧值，静态写入归属决定提交掩码，保持条件不成立时不改变状态。检查失败发生
在时序求值阶段时，不提交该边沿状态。

第一版是 **单实例、单 CTA 的设备驻留原型**。没有 CPU 每拍调度、线程池、
主机 dirty 通知或每拍 kernel launch。行为块与设备 lane 的分配由后端决定，
本版使用静态分派；异构块的分支分歧、屏障开销和单 CTA 并行规模尚未优化。
共享存储预算超过 48 KiB 的设计在编译时拒绝，不能用它直接声称已经承载整核。
当前 driver 提供完整的边沿前后记录，属于验证配置，不是性能测量配置。

跨 CTA 执行、设备端内存/总线环境和整核模块连接尚未实现。未来会影响输入的环境
状态必须进入设备模型，或设置准确停止点；不能用记录下来的 RTL 响应替代环境。

同步依据：[NVIDIA CUDA 同步函数与内存可见性说明](https://docs.nvidia.com/cuda/archive/12.3.0/cuda-c-programming-guide/)。
块内屏障的保证不能延伸成跨 CUDA thread block 的保证。

## 验证

在工程根目录的 Ubuntu shell 中执行：

    make -C npc/rv64/model test-behavior

当前 25 项 unittest 包括：

| 层次 | 实际检查 |
| --- | --- |
| 基础语义 / R64Counter | 9 项；原 RTL 2,000 周期、3,999 个观测点，比较 value_o 与全部 21 位进位缓存 |
| 宽位/动态语义 / R64LsuRequestQueue | 5 项；4 组参数各 1,500 周期，合计 12,000 个边沿前后观测点，比较全部输出与 19 个内部状态字段 |
| 代码生成 | 5 项；生成代码主机执行的 400 个混合边沿语义样本、1,000 周期 counter、700 周期 queue；queue 再与原 RTL 独立对照 |
| GPU 优化语义 | 3 项；融合、字投影与原有序解释器对照，覆盖条件检查、旧状态、blocking 自引用与动态 NBA 地址捕获 |
| 模块网络 | 3 项；两组生产 LSU 完成路径各 1,200 周期、完整输出及 69 个状态字段，端口/反馈验证与中间值分批求值对照 |
| CUDA 编译 | 属于代码生成测试；counter、宽位 queue、混合边沿语义模型的真实 CUDA driver 和 kernel 编译、链接，未运行 GPU |

队列刺激覆盖填满、等待、同拍 push/pop、取消、flush、age 清除、未发布 payload
预捕获；额外故意违反 credit 和 prepared-cancel 约束，确认原 RTL 与模型都会拒绝。
生成代码还检查跨机器字加减、动态地址捕获、越界选择、blocking 自引用、不同块写
同一字的不相交位及正负边沿隔离；主机执行开启 undefined-behavior sanitizer。

Icarus 直接执行仓库原始 RTL，队列启用 R64_ASSERT。为比较未复位 payload 等内部
状态，测试平台显式将所有队列状态初始化为零，与模型的两态初始条件一致；生产 RTL
未添加初始化。Counter 首个复位前的未知状态不作为两态比较点。模型每拍随机打乱
时序块执行顺序及 Patch 提交顺序，以检测对求值先后的错误依赖。

所有测试编译文件位于 TemporaryDirectory，成功或失败后都会清理。
没有 CUDA 编译器时该项明确 SKIP，不能把 SKIP 当作设备编译通过。

## 导出与执行入口

导出包含语句 AST、类型、触发、初始状态、参数及源位置的行为程序：

    python3 -B npc/rv64/model/behavior/describe.py --model lsu-queue \
      --out tmp/r64-queue-behavior.json

生成并编译设备 driver（此命令不启动 GPU）：

    make -C npc/rv64/model behavior-cuda BEHAVIOR_CUDA_MODEL=lsu-queue

默认输出 npc/rv64/build/behavior-cuda/lsu-queue/behavior-cuda。
可通过 BEHAVIOR_CUDA_BUILD、CUDA_HOST_CXX、CUDA_ARCH 覆盖目录、宿主编译器和架构。

driver 要求显式选择 --gpu 或 --host-oracle，GPU 失败不会自动退回主机。
输入每行包含：边沿标志（0=posedge、1=negedge），随后按模型 inputs 顺序列出
各输入的 32 位字，低字在前，均为十六进制。每个字段必须在声明位宽内。
输出每条成功边沿的前后两行；字段顺序为 outputs、states，每个字段是完整十六进制值。
失败时返回非零退出码。test_codegen.py 的 stimulus_text 可生成输入文件。

例如 counter 的一次复位输入：

    make -C npc/rv64/model behavior-cuda BEHAVIOR_CUDA_MODEL=counter
    printf '0 1 1 3 1 ffffffff ffffffff\n' | \
      npc/rv64/build/behavior-cuda/counter/behavior-cuda --gpu

当前 Intel 核显不能执行这个 CUDA 入口；核显请使用 IGPU.md 中的 Direct3D12 入口。
--host-oracle 只验证生成代码语义，不测 GPU 性能。

## 尚未覆盖

有符号类型、一般动态数组/存储器、case/过程循环 AST、多时钟/异步复位、跨块可见的
时序 blocking 写入、四态和完整 SystemVerilog 事件区域尚未实现。
已有 LSU 完成路径的 I/O 网络；翻译/cache/LSQ/退休和设备环境尚未加入，仍不能执行整核。
整核验收仍要求同镜像、输入、初始条件与统计区间下，退休/异常和自然终止绝对周期
与 RTL 零误差。单实例端到端速度另行实测；模块通过、设备编译或批量吞吐不能替代它。
