# 承岳64 RTL 目录

本目录只保存 **ChengYue64（承岳64）** 主线的可综合 RTL、源码清单和模块说明。
版本由 [../core-version.mk](../core-version.mk) 定义，默认源码直接列在
[filelist.mk](filelist.mk)，可选 Tensor/NPU 源码由 [tensor-filelist.mk](tensor-filelist.mk) 补充。

| 目录 | 职责 | 结构与接口入口 |
| --- | --- | --- |
| [core/](core/) | CPU 顶层连接与跨域控制 | [全核拓扑](TOPOLOGY.md)、[R64CoreTop.v](core/R64CoreTop.v) |
| [frontend/](frontend/) | 取指、对齐、预测和预解码 | [Frontend 拓扑](frontend/TOPOLOGY.md) |
| [backend/](backend/) | 原子分配、重命名、发射、操作数、整数执行、完成与 ROB 退休窗口 | [Backend 拓扑](backend/TOPOLOGY.md) |
| [fp/](fp/) | 浮点数值执行与本地完成 | [FP 拓扑](fp/TOPOLOGY.md) |
| [control/](control/) | Control 内聚 Commit、CSR、特权、trap 与 Serial | [Control 拓扑](control/TOPOLOGY.md) |
| [memory/](memory/) | I/D 翻译、权限/属性、I-cache 和数据侧集成 | [Memory 拓扑](memory/TOPOLOGY.md) |
| [lsu/](lsu/) | LSQ、转发、内存服务与 D-cache | [LSU 拓扑](lsu/TOPOLOGY.md)、[目录说明](lsu/README.md) |
| [bus/](bus/) | 核侧 AXI 适配器及复用的中断/UART/syscon/错误响应外设 | [BUS/平台拓扑](bus/TOPOLOGY.md) |
| [platform/](platform/) | Fabric、地址图、设备桥、系统顶层及可选 Tensor 接入 | [平台说明](platform/README.md) |
| [include/](include/) | 共享编码、基础宽度和默认地址宏 | [define.v](include/define.v)；生产结构参数以实际实例为准 |

默认 CPU/系统顶层为 `R64CoreTop` / `R64SystemTop`，可选 `R64TensorSystemTop`。
模块位置与连接分别见 [MODULES.md](MODULES.md) 和 [TOPOLOGY.md](TOPOLOGY.md)。

2026-10-09 各域拓扑按同一阅读方式整理：生产配置与文件职责 → 实际实例 →
数据/资格/取消/副作用边界 → 状态 owner → 验证入口与历史测量。
目录不等于实例子树；例如 FP 在 CoreTop 下独立实例化，并复用 backend 目录的数值 helper。
Control 封闭退休/CSR 内部协议，Frontend.access 管理取指访问，LSU.translation_owners 管理已接受翻译的返回归属；
这些层级保持原有接收边沿，不代表增加流水级。

`include/define.v` 仍包含供其它使用方引用的 `OOO_*` 默认宏，不能据此推断本核的 ROB/IQ 容量。
当前 ROB32、默认 IQ16、LSQ20 等配置来自 CoreTop、Backend、Memory 的实际参数；
UOP/META/RESULT 格式见 [R64Uop.vh](backend/R64Uop.vh)，平台地址组合见
[R64PlatformMap.vh](platform/R64PlatformMap.vh)。宏定义文件本身没有状态 owner 或握手边界。

仿真封装、DPI 和 NPU 宿主桥位于 [../sim/vsrc/](../sim/vsrc/)；
测试激励和比较 oracle 位于 [../testbench/](../testbench/README.md)。
旧核源码保存在[封存包](../../pack/rv64core-legacy-20260916/README.md)，
旧仿真和构建入口见 [../legacy/](../legacy/README.md)。`vsrc/` 不保留旧核或旧开发名的源码链接。

## RTL 表达约定

- 默认直接表达，能不用 `generate` / `function` 就不用；它们只承担机械重复、
  位切片、字段拼接和局部数值计算等 dirty work，不为统一形式或减少行数增加抽象。
  单条 `assign` 能清楚表达的切片或拼接直接写出，不另包 helper。
- 只有确实需要复制的规则硬件使用命名 `generate`，例如大量同构 lane、数组条目或
  重复数值单元；保留索引、位宽和语义名称。少量短逻辑、已有清楚的过程循环无需机械改写。
  少量固定且角色不同的实例保留具名连接，不为使用 `generate` 额外引入打包、解包和索引映射。
- 固定端口、执行源和字段位置使用有含义的名称；非顺序映射用显式常量表列出，
  让设备或操作数角色能直接追踪。复用结构注明循环维度、打包顺序和树的选择方向，
  在实际使用处给复杂切片命名；不机械替换所有数字，也不增加无意义的转接信号。
- 关键数据路径的资源共享、操作数选择、仲裁优先级、流水寄存边界和
  valid/ready、flush/kill 控制保持显式，不混淆不同职责。
- `function` 限于输入输出清楚的小型纯组合运算（编码、计数、shift/jam 等）和
  elaboration-time 常量计算，使用到的运行时信号通过输入参数显式传入；执行组选择、状态更新、
  事务归属及取消资格决策直接在模块结构中表达。
