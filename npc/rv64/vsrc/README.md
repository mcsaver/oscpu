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
