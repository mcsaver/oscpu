# CPU 网络模型

GPU 后端的当前设计方向见 [GPU_DATAFLOW.md](GPU_DATAFLOW.md)：以 always 行为描述为起点，逐步组合模块与 CPU。[行为基础实现](../behavior/README.md)已开始，尚无 GPU 整核执行结果。

**整核独立执行模型见 [CPU.md](CPU.md)**；共享旧状态的并行实验见 [PARALLEL.md](PARALLEL.md)。它已覆盖整个当前 CPU 的详细状态与 I/O，
使用变化传播调度；高层事务协议迁移仍需逐模块推进。下面保留独立队列/仲裁原型
的语义与测量，不能将其加速倍数当作整核速度。

## 同源生成的事务网络原型

本目录实现了第一段可执行事务网络：多个输入队列 → 带输出保持的轮转仲裁器 →
独立反压接收端。取消控制覆盖所有可撤销消息。该原型没有接入生产 CPU，
不代表整核 CPI 已对齐，也不替代现有 DiffTest。

控制状态转移只有一份，位于 semantics.py。emit.py 将同一份无符号定宽表达式图
输出为 C++ 模型和 Verilog-2001 硬件。tests/reference.py 使用独立 deque/list 算法，
不解释公共表达式图，作为两端逐周期比较及协议性质检查的参照。

## 运行

在工作区根目录的 Ubuntu shell 中执行：

    PYTHONDONTWRITEBYTECODE=1 python3 npc/rv64/model/network/run.py \
      --out tmp/rv64-protocol-network

依赖 Python 3.9+、g++、Verilator 和 Icarus Verilog。默认依次验证三种配置：

- completion.json：3 输入，队列深度 2/2/2，2 输出，16 位 owner，64 位数据。
- permuted_depths：深度 3/1/4，输入优先级连接和输出连接倒序，17 位数据。
- single_lane：1 输入、深度 1、1 输出、8 位 owner、1 位数据。

每种配置运行定向与固定种子混合激励，比较独立参考、C++、Verilator、Icarus
全部通道的逐周期输出，再做三次同负载 C++ / Verilator 速度测量。
两端 benchmark 使用相同的带反馈流量发生器，分别依据自身握手推进输入；
只输出摘要和 checksum，不读取参考模型或已记录的 RTL 输出。

    make -C npc/rv64/model test-network
    make -C npc/rv64/model network

前一个命令只验证，不做速度测量。自定义单个配置：

    PYTHONDONTWRITEBYTECODE=1 python3 npc/rv64/model/network/run.py \
      --config path/to/network.json --single-config --out tmp/network-custom

改变容量、连接或位宽会重新生成两端。第一版只接受“每个源一个队列 → 一个
rr_hold → 接收端”这一明确拓扑；类型、端口数量、连接完整性或组合依赖不合法
会报错，不会默认猜测连接或执行顺序。原语支持 1..8 个源、1..N 个出口、1..8
深队列、1..64 位数据/owner、1..4 个取消端口。内置流量测试使用至少 8 位 owner；
更小身份空间需要专门限制在飞事务的测试环境。

只生成源代码而不构建：

    PYTHONDONTWRITEBYTECODE=1 python3 npc/rv64/model/network/emit.py \
      --config npc/rv64/model/network/completion.json --out tmp/network-generated

输出包含 Network.v、network_model.hpp、两端共用的端口布局、Verilator 适配器
及 manifest.json。硬件的原语状态在一个 Network 顶层中展开，尚未作为生产
模块进入 CPU filelist。原型观察端口同时用于两端验证/计时，未做物理 PPA 评价。

## 已测结果

本次保存的简要结果见 [VALIDATION.json](VALIDATION.json)：
三种配置共 13,132 个目标周期，C++、Verilator、Icarus 均与独立参考逐周期一致，
每个实现共比较 508,284 个输出字段。包含 7 项生成器/配置边界测试。

每个配置另进行三次、每次一千万目标周期的同负载速度测量，取执行时间中位数：

| 配置 | C++ | Verilator | Verilator 时间 / C++ 时间 |
| --- | ---: | ---: | ---: |
| 默认 3×2 | 0.917 s | 1.577 s | 1.72× |
| 深度及连接变化 | 0.952 s | 1.785 s | 1.88× |
| 单通道边界 | 0.186 s | 0.719 s | 3.86× |

以上只属于这个小网络，测量环境为当前 WSL、g++ -O3、Verilator 5.020，
没有声称生产 CPU 获得相同加速。

## 周期及协议

完整设计范围见 [PROTOCOL.md](PROTOCOL.md)。当前实现规定：

- 一个 step 观察 S[t] 和本周期输入，返回边沿前通道行为，然后提交 S[t+1]。
- 模型和 RTL 都先执行一次同步复位；首次输入周期的旧状态一致。
- src_offer 表示原始发送意图。有效通道 valid 由 offer、复位及完整 owner
  取消匹配共同限定；fire 为这个有效 valid 与 ready 的与。
- ready 只使用旧占用。满队列本拍出队/取消，不会产生本拍新信用。
- 无空队列旁路；出队、稳定压缩未取消项、追加新项在边沿生效。
- 输出各有一个保持槽，不能在旧槽已满时同拍消费并替换。轮转优先级只在实际
  接受输入后推进；被阻塞的输出不换消息或 lane。
- 取消按完整 owner 匹配，优先于交付；不会把低位 slot 相同的不同代际混淆。
  owner 目前作为不透明定宽身份处理，完整 CPU 的身份分配器尚未实现。
- 只支持可撤销结果，没有模拟不可撤销 store、AXI 排空或 ROB 提交授权。
- C++ 执行当前仍逐目标周期推进，并非可跨空闲周期跳跃的事件调度器。

一个保持槽且使用旧占用信用，会限制单出口持续吞吐为每两拍一条。这个代价
属于明确的网络规则；增加出口保持容量或同拍替换能力需要声明并实现新的
原语语义。第一版未把这些实现差异压缩成平均延迟。

## 验证与报告

run.py 会保留：

- config.json / generated/manifest.json：实际配置、连线映射和端口列表。
- generated/：可审阅、可重新构建的两端源代码。
- report.json：全部通道对照、独立协议检查、事件统计和速度样本。
- statistics.csv：接受/交付、占用、等待及最长反压区间。
- commands.log：真实构建与运行输出；失败时另存首个差异及输入上下文。
- summary.json：所有配置总体结果。

协议检查包括保持、旧状态信用、容量、完整身份、消息不丢失/不重复、取消、
有容量条件下的仲裁进展，以及包含复位丢弃的事务守恒。等待类别可能重叠，
不能把这些计数直接相加当作 CPI。计时报告区分构建、初始化、执行和进程耗时。

逐周期零差异结论只覆盖实际测试的配置及输入。benchmark 的完整输出 checksum
一致是另外一项长流量检查，不是对其全部周期的形式化证明。
同源生成仍可能共享错误，独立参考和性质检查不会被双端自比替代。

C++ 与 RTL benchmark 都保留容量/指针断言、同一流量发生器及全输出 checksum。
速度比只适用于这个网络；没有整核执行、NEMU DiffTest 或内存系统成本，
不能外推为当前 CPU 相对 Verilator 的加速倍数。

临时二进制、对象文件、Icarus 文件、输入/输出长轨迹位于本次运行独占的
TemporaryDirectory，成功、失败或中断后清理。可审阅的生成源码和简要报告保留。
生产 CPU 的现有编译目录不在清理范围内。

## 后续工作

首先增加表达生产 WB 注册 grant、需求提示及身份查询的协议节点，实现当前
结果回流子网与模型、原生产 RTL 的三方周期对照。现在的 rr_hold 策略与生产
R64Writeback 不相同，不能直接替换并宣称旧周期不变。

再扩展依赖合流、资源联合分配、执行节点和不可撤销事务，逐步替换当前整核底座
中的 RTL 详细节点。这样每迁移一个子网仍可执行完整程序进行对照。
原有 correct-path trace 模型仍是独立的近似模型。
