# 旧 RV64 仿真宿主

本目录保存旧 `NpcTop/Ooo*` 核的宿主实现。承岳64默认构建使用
[当前仿真环境](../sim/README.md)，不编译这里的 C/C++ 代码。

| 路径 | 职责 |
| --- | --- |
| `sim/src/` | 旧 CPU 执行驱动、DPI、内存、设备、monitor 与 trace |
| `sim/include/` | 上述宿主的头文件和设备地址定义 |
| `sim/difftest/` | 旧宿主的 NEMU 动态库适配与状态比较实现 |
| [../sim/vsrc/](../sim/vsrc/) | 纯仿真 RTL，包括旧 `NpcSimTop`、DPI/virtio 适配与当前 NPU 仿真桥 |

这些文件于 2026-09-18 从 `csrc/` 按职责迁入；源码内容保持不变。
旧构建仍由 [Makefile.legacy](../Makefile.legacy) 定义，从工作区根运行：

```sh
make -C npc/rv64 -f Makefile.legacy lint
make -C npc/rv64 -f Makefile.legacy
```

完整冻结源码及当时的配置、工具和报告保存在
[2026-09-16 封存包](../../pack/rv64core-legacy-20260916/README.md)。
此目录的兼容构建与旧验证工具不代表承岳64的功能或 PPA 结果；历史资格与摘要必须按其
原始文件身份解释，目录迁移不会自动重签旧结果。
