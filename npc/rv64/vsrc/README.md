# 承岳64 RTL 目录

正式版本：**ChengYue64（承岳64）v1.0.0**。版本真源为 [../core-version.mk](../core-version.mk)。

| 目录 / 文件 | 用途 |
| --- | --- |
| [chengyue64/](chengyue64/) | 正式原生双发射乱序核；内部模块沿用 R64 前缀 |
| [filelist.mk](filelist.mk) | 默认仿真和综合的源码入口 |
| [bus/](bus/) | 主线使用的共享 AXI 外设 IP |
| [include/](include/) | 共享硬件定义 |
| [../sim/vsrc/](../sim/vsrc/) | RTL 仿真封装、DPI 与平台接入适配；R64NpuCpuSim 用于完整 NPU 消费者，不属于可综合核源码 |
| `rebuild` | 指向 `chengyue64` 的兼容链接 |
| `core/frontend/execute/memory/...` | 指向旧核归档的兼容链接，供历史工具和少量测试 oracle 使用 |
| `filelist.legacy.mk` | 旧核兼容源码清单；不被默认构建包含 |

旧核独有的 15 个 RTL 目录已迁移至
[../../pack/rv64core-legacy-20260916/rv64/vsrc/](../../pack/rv64core-legacy-20260916/rv64/vsrc/)。
旧目录说明原文随包保存在 [归档 README](../../pack/rv64core-legacy-20260916/rv64/vsrc/README.md)。

架构从 [../ARCHITECTURE.md](../ARCHITECTURE.md) 进入，
模块列表与拓扑见 [chengyue64/MODULES.md](chengyue64/MODULES.md) 和
[chengyue64/TOPOLOGY.md](chengyue64/TOPOLOGY.md)。
默认顶层为 `R64CoreTop` / `R64SystemTop`，可选 `R64TensorSystemTop`；
旧 `NpcTop` / `Ooo*` 主核不进入默认产品 filelist。
