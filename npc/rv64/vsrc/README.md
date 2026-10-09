# 承岳64 RTL 目录

本目录只保存 **ChengYue64（承岳64）** 主线的可综合 RTL、源码清单和模块说明。
版本由 [../core-version.mk](../core-version.mk) 定义，默认源码直接列在
[filelist.mk](filelist.mk)，可选 Tensor/NPU 源码由 [tensor-filelist.mk](tensor-filelist.mk) 补充。

| 目录 | 职责 |
| --- | --- |
| [core/](core/) | CPU 顶层连接 |
| [frontend/](frontend/) | 取指、指令对齐、预测与解码 |
| [backend/](backend/) | 重命名、发射、寄存器读取、执行调度、写回与退休 |
| [fp/](fp/) | 浮点数值执行 |
| [control/](control/) | CSR、特权、trap 与序列化控制 |
| [memory/](memory/) | 地址翻译、权限和物理内存属性 |
| [lsu/](lsu/) | 访存队列、内存服务与数据缓存 |
| [bus/](bus/) | 主线 AXI 桥及复用的 CLINT、PLIC、UART、syscon 及默认错误响应外设 |
| [platform/](platform/) | 系统互连、地址图、Tensor 接入和系统顶层 |
| [include/](include/) | 共享硬件定义 |

默认 CPU/系统顶层为 `R64CoreTop` / `R64SystemTop`，可选 `R64TensorSystemTop`。
模块位置与连接分别见 [MODULES.md](MODULES.md) 和 [TOPOLOGY.md](TOPOLOGY.md)。

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
