# LSU 完成路径的 GPU 行为网络

当前实现把真实 LSU 的三个事件源队列、事件选择与完成队列连接成同一个行为模型：
response_queue、faults、forwarding_results → 轮转事件选择 → R64LsuCompletion。
行为实例保留名称、状态与原 always 来源；生产 RTL 不变。

这是一段真实相连的 LSU 子系统。外部边界位于三个 ingress 队列的 in_fire/tag/data、
取消/reset/flush 和完成结果 out_ready。翻译、cache、LSQ owner、退休与内存环境仍在
边界外，尚不能运行整核程序或给出整核 CPI。

## 设备中的反馈

- 三个双 lane、每 lane 两项的请求队列提供最多六个待完成事件。
- R64LsuOrderSelect 根据保存的轮转位置选择前两个有效事件。
- 完成队列的当前占用产生 0/1/2 项接收 credit，决定源队列本拍的 pop。
- 只有实际 completion capture 才更新轮转位置。
- 完成队列保留物理 lane、front/skid、tag、140 位 result 与 turn。
- 下游反压、kill、flush、满队列、同拍 push/pop 均参与下一拍的状态。

三个源队列的 payload 格式分别为原 RTL 的 152 / 70 / 77 位。保留 load_value 的
符号扩展、浮点 boxing、AMO 条件、offset、异常 cause/tval 格式化，以及空闲 payload
预写行为。没有用固定延迟服务替代完成队列，也没有回放 RTL 内部 grant/credit。

外部输入序列是模块测试刺激；其中 in_fire 按合法的 ingress credit 生成。输入在
dispatch 前装载，之后内部 ready、grant、优先级、队列状态完全由 GPU 模型推进。
该测试刺激不等于独立 CPU 执行环境。

## 编译和执行

compose.py 将端口连接展开为带实例命名空间的行为块。端口缺失、重复连接、位宽
不匹配及真实组合环由连接层/原 Model 校验拒绝；通过寄存器的反馈保持合法。
所有时序块共用边沿前状态，不按实例先后提交。

完全内联的版本使代码生成与 DXC 优化成本显著上升。新 dataflow_codegen.py
允许在明确的组合信号边界保留中间值，再按其依赖自动分批：

1. 读取队列当前 payload、tag、valid、完成 credit 和轮转顺序。
2. 并行完成事件选择、格式化，以及只依赖上一批结果的控制计算。
3. 形成接收 grant 与选中 payload。
4. 计算所有下一状态和原协议检查；全部检查通过后统一提交。

这些是同一个目标周期内部的 GPU 计算批次，不引入额外 RTL 周期。
默认配置为 69 个状态字段、117 个状态字、75 个组合中间字，合计 772 字节共享存储
（含检查状态）；256 线程、WaveSize(8)，更新批次为 137 条状态字/检查规则。
正常关闭 trace 时每个边沿有 3 次组合依赖同步和 2 次提交同步。

native_codegen.py 将表达式直接降为 uint32 运算和显式进位、掩码、移位；宽值在
生成器中是机器字元组，不为每次表达式运算生成一层宽结构体函数。结构体仅用于
输入/输出适配。这解决了该网络在 DXC 优化时超过 180 秒的编译问题：当前两组
带 trace 的 shader 编译分别为 0.374 / 0.385 秒，默认无 trace 版本为 0.245 秒。

每个批次沿用 SIMD 规则族和机器字分工，共享规则代码与描述符。当前/下一状态隔离，
每个状态字由唯一 lane 提交。提交前检查失败时整个网络保持上一成功边沿的状态，不能只
回滚报错子模块而让其余子模块前进；提交后的 phase 2 检查失败保留已经提交的新状态。

trace 配置在提交后重新计算边界值并记录边沿后状态；性能配置在编译期移除这条路径。
CPU 每次运行只发一次 dispatch；GPU 内部循环跨越全部目标边沿。

目前仍限于一个 GPU thread group。连接层可以表达更大的网络，但本后端没有跨组
同步、设备内存总线模型或整核调度能力。模块连接通过不能替代这些工作。

## 独立验证

test_terminal.py 直接实例化仓库中的 R64LsuRequestQueue、R64LsuOrderSelect、
R64LsuCompletion。父模块的仲裁/轮转、格式化函数和事件结果赋值从原 R64Lsu.v
逐字读取，用独立 Icarus 仿真执行；参考端不消费行为更新表达式。

比较所有顶层输出及 69 个状态字段的边沿前后值。测试台显式统一包括未复位 payload
在内的两态初始状态；生产 RTL 不添加初始化，原 R64_ASSERT 保持启用。

两组参数：

- TAG_W=9、ROB_W=5、原取消模式。
- TAG_W=12、ROB_W=6、prepared-cancel 模式。

每组 1,200 周期，覆盖六路竞争、双接收、完成队列满、同拍 push/pop、取消驻留项、
flush、轮转回绕、skid 前移，最后停止输入并确认网络自然排空。
真实 GPU 验证还故意违反 ingress credit，比较失败周期并确认整个网络无部分提交。
单独的 phase 0 / 2 设备用例检查非零初态及提交前后组合检查语义。
当前两组共 2,400 周期、4,800 组完整边沿前后观察，GPU / 行为模型 / 原 RTL 零差异。

新原生整数后端另通过 1,800 个 load 格式化边沿和 400 个宽整数混合边沿。前者
针对本次发现的符号扩展错误，覆盖全部 func 编码、offset、AMO 条件、正负边界和
随机值，使用独立 Python 整数参考；后者覆盖 130 位进借位、65 位索引、越界移位、
动态部分写入和正负边沿。它们属于设备语义回归，不计作额外生产 RTL 周期。

设备验证与计时记录见 [TERMINAL_GPU_VALIDATION.json](TERMINAL_GPU_VALIDATION.json)；
该报告独立于前一轮单模块 [IGPU_OPTIMIZATION.json](IGPU_OPTIMIZATION.json)。

## 当前单实例性能

以下来自上述报告，1,200 个目标周期，关闭 trace，保留协议检查，各运行 5 次取中位数。

| 测量 | 耗时 |
| --- | ---: |
| GPU 内核设备 timestamp | 5.079 ms |
| C++ 行为状态推进循环 | 1.421 ms |
| GPU 整进程调用 | 473.159 ms |
| C++ 整进程调用 | 3.011 ms |

GPU 内核仍为 C++ 循环的 3.57 倍耗时，约 23.6 万目标周期/秒。该网络扩大了同一个
实例内部的并行工作，但尚未占满整片核显，也未采集硬件 occupancy 计数器；不能
把线程数称为 GPU 利用率。整进程包含每次新建设备/pipeline 的成本，还没有复用
持久运行时。此结果不与前一轮不同规模模块的时间作加速比，也不是 Verilator 比较。

## 复现

在工程根目录的 Ubuntu shell：

    make -C npc/rv64/model test-behavior-terminal-gpu

这会运行两组 RTL/GPU 逐周期对照、非法 credit 检查，并对默认参数进行 5 次 GPU / C++
计时。GPU 内核时间使用设备 timestamp；CPU 参考时间只计 C++ 行为推进循环。双方
均检查最终完整状态。整进程时间另外记录，包含设备/pipeline 初始化等开销。

仅运行正确性验证并保留既有性能报告：

    python3 -B npc/rv64/model/behavior/validate_terminal_gpu.py --skip-benchmark \
      --out tmp/terminal-correctness.json

导出含完整有序行为、实例与保留边界的描述：

    python3 -B npc/rv64/model/behavior/describe.py --model lsu-terminal \
      --out tmp/lsu-terminal-behavior.json

临时 HLSL、DXIL、RTL testbench、测试程序与输入/输出位于 TemporaryDirectory，
正常结束或异常返回时清理；保留可复用的核显运行时/编译器依赖和 JSON 报告。
